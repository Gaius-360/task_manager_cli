import 'package:task_manager_cli/exceptions.dart';

enum Priority { low, medium, high }

abstract class Task implements Comparable<Task> {
  String title;
  Priority priority;
  DateTime? deadline;
  bool isDone;

  Task({
    required this.title,
    required this.priority,
    this.deadline,
    this.isDone = false,
  });

  String get type;

  String describe();

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'priority': priority.name,
      'deadline': deadline?.toIso8601String(),
      'isDone': isDone,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final String title;
    final Priority priority;
    final DateTime? deadline;
    final bool isDone;
    try {
      title = json['title'] as String;
      priority = Priority.values.byName(json['priority'] as String);
      final deadlineStr = json['deadline'] as String?;
      deadline = deadlineStr != null ? DateTime.parse(deadlineStr) : null;
      isDone = json['isDone'] as bool;
    } on TypeError catch (e) {
      throw InvalidTaskDataException('Données de tâche invalides: $e');
    } on ArgumentError catch (e) {
      throw InvalidTaskDataException('Priorité invalide dans les données: $e');
    } on FormatException catch (e) {
      throw InvalidTaskDataException('Date invalide dans les données: $e');
    }

    switch (json['type']) {
      case 'simple':
        return SimpleTask(
          title: title,
          priority: priority,
          deadline: deadline,
          isDone: isDone,
        );
      case 'urgent':
        if (deadline == null) {
          throw InvalidTaskDataException(
            'Une tâche urgente doit avoir une échéance: $title',
          );
        }
        return UrgentTask(
          title: title,
          priority: priority,
          deadline: deadline,
          isDone: isDone,
        );
      default:
        throw InvalidTaskDataException(
          'Type de tâche inconnu: ${json['type']}',
        );
    }
  }

  @override
  int compareTo(Task other) {
    final byPriority = other.priority.index - priority.index;
    if (byPriority != 0) return byPriority;
    if (deadline == null && other.deadline == null) return 0;
    if (deadline == null) return 1;
    if (other.deadline == null) return -1;
    return deadline!.compareTo(other.deadline!);
  }

  @override
  String toString() => describe();
}

class SimpleTask extends Task {
  SimpleTask({
    required super.title,
    required super.priority,
    super.deadline,
    super.isDone,
  });

  @override
  String get type => 'simple';

  @override
  String describe() => title;
}

class UrgentTask extends Task {
  UrgentTask({
    required super.title,
    required super.priority,
    required DateTime deadline,
    super.isDone,
  }) : super(deadline: deadline);

  @override
  String get type => 'urgent';

  @override
  String describe() => 'URGENT: $title';
}
