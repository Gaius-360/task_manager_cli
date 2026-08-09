import 'dart:convert';
import 'dart:io';

import 'package:task_manager_cli/exceptions.dart';
import 'package:task_manager_cli/task.dart';

/// Generic, file-backed repository for storing a list of items of type [T].
class Repository<T> {
  final String storagePath;
  final Map<String, dynamic> Function(T item) toJson;
  final T Function(Map<String, dynamic> json) fromJson;
  final List<T> _items = [];

  Repository({
    required this.storagePath,
    required this.toJson,
    required this.fromJson,
  });

  List<T> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final file = File(storagePath);
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return;

      final decoded = jsonDecode(content) as List<dynamic>;
      _items
        ..clear()
        ..addAll(decoded.map((e) => fromJson(e as Map<String, dynamic>)));
    } on FileSystemException catch (e) {
      throw StorageException('Impossible de lire $storagePath: ${e.message}');
    } on FormatException catch (e) {
      throw StorageException('Fichier de données corrompu ($storagePath): $e');
    }
  }

  Future<void> save() async {
    try {
      final file = File(storagePath);
      final encoded = jsonEncode(_items.map(toJson).toList());
      await file.writeAsString(encoded);
    } on FileSystemException catch (e) {
      throw StorageException('Impossible d\'écrire $storagePath: ${e.message}');
    }
  }

  void add(T item) {
    _items.add(item);
  }

  T itemAt(int index) {
    if (index < 0 || index >= _items.length) {
      throw ItemNotFoundException('Aucun élément à l\'index ${index + 1}');
    }
    return _items[index];
  }

  T removeAt(int index) {
    final item = itemAt(index);
    _items.removeAt(index);
    return item;
  }
}

enum TaskSort { none, priority, deadline }

/// Task-specific repository built on top of the generic [Repository].
class TaskRepository extends Repository<Task> {
  TaskRepository(String storagePath)
    : super(
        storagePath: storagePath,
        toJson: (task) => task.toJson(),
        fromJson: Task.fromJson,
      );

  Task complete(int index) {
    final task = itemAt(index);
    task.isDone = true;
    return task;
  }

  /// Returns tasks paired with their original storage index, so callers can
  /// still reference `done`/`remove` correctly after filtering or sorting.
  List<MapEntry<int, Task>> list({
    bool? isDone,
    Priority? priority,
    TaskSort sort = TaskSort.none,
  }) {
    var entries = <MapEntry<int, Task>>[
      for (var i = 0; i < items.length; i++) MapEntry(i, items[i]),
    ];

    entries = entries.where((entry) {
      if (isDone != null && entry.value.isDone != isDone) return false;
      if (priority != null && entry.value.priority != priority) return false;
      return true;
    }).toList();

    switch (sort) {
      case TaskSort.priority:
        entries.sort((a, b) => a.value.compareTo(b.value));
      case TaskSort.deadline:
        entries.sort((a, b) => _compareDeadline(a.value, b.value));
      case TaskSort.none:
        break;
    }

    return entries;
  }

  int _compareDeadline(Task a, Task b) {
    if (a.deadline == null && b.deadline == null) return 0;
    if (a.deadline == null) return 1;
    if (b.deadline == null) return -1;
    return a.deadline!.compareTo(b.deadline!);
  }
}
