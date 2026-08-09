import 'dart:io';

import 'package:task_manager_cli/exceptions.dart';
import 'package:task_manager_cli/repository.dart';
import 'package:task_manager_cli/task.dart';

class App {
  final TaskRepository repository;

  App(this.repository);

  Future<void> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      _printHelp();
      return;
    }

    final command = arguments.first;
    final rest = arguments.skip(1).toList();

    try {
      switch (command) {
        case 'add':
          _add(rest);
          await repository.save();
          break;
        case 'list':
          _list(rest);
          break;
        case 'done':
          _done(rest);
          await repository.save();
          break;
        case 'remove':
          _remove(rest);
          await repository.save();
          break;
        case 'help':
        case '--help':
        case '-h':
          _printHelp();
          break;
        default:
          stderr.writeln('Commande inconnue: $command');
          _printHelp();
          exitCode = 64;
      }
    } on ItemNotFoundException catch (e) {
      stderr.writeln(e.message);
      exitCode = 1;
    } on InvalidPriorityException catch (e) {
      stderr.writeln(e.message);
      exitCode = 1;
    } on InvalidTaskDataException catch (e) {
      stderr.writeln(e.message);
      exitCode = 1;
    } on StorageException catch (e) {
      stderr.writeln(e.message);
      exitCode = 1;
    }
  }

  void _add(List<String> args) {
    final options = _parseOptions(args);
    if (options.positional.isEmpty) {
      throw InvalidTaskDataException('Le titre de la tâche est requis.');
    }

    final title = options.positional.join(' ');
    final priority = _parsePriority(options.named['priority']);
    final deadline = _parseDeadline(options.named['deadline']);
    final isUrgent = options.flags.contains('urgent');

    Task task;
    if (isUrgent) {
      if (deadline == null) {
        throw InvalidTaskDataException(
          'Une tâche urgente nécessite une échéance (--deadline=AAAA-MM-JJ).',
        );
      }
      task = UrgentTask(title: title, priority: priority, deadline: deadline);
    } else {
      task = SimpleTask(title: title, priority: priority, deadline: deadline);
    }

    repository.add(task);
    print('Tâche ajoutée: ${task.describe()}');
  }

  void _list(List<String> args) {
    final options = _parseOptions(args);

    bool? isDone;
    if (options.flags.contains('done')) isDone = true;
    if (options.flags.contains('pending')) isDone = false;

    final priority = options.named.containsKey('priority')
        ? _parsePriority(options.named['priority'])
        : null;
    final sort = _parseSort(options.named['sort']);

    final entries = repository.list(
      isDone: isDone,
      priority: priority,
      sort: sort,
    );

    if (entries.isEmpty) {
      print('Aucune tâche.');
      return;
    }

    for (final entry in entries) {
      final task = entry.value;
      final status = task.isDone ? '[x]' : '[ ]';
      final deadlineLabel = task.deadline != null
          ? ' (échéance: ${_formatDate(task.deadline!)})'
          : '';
      print(
        '${entry.key + 1}. $status ${task.describe()} '
        '- ${task.priority.name}$deadlineLabel',
      );
    }
  }

  void _done(List<String> args) {
    final index = _parseIndex(args);
    final task = repository.complete(index);
    print('Tâche terminée: ${task.describe()}');
  }

  void _remove(List<String> args) {
    final index = _parseIndex(args);
    final task = repository.removeAt(index);
    print('Tâche supprimée: ${task.describe()}');
  }

  int _parseIndex(List<String> args) {
    if (args.isEmpty) {
      throw InvalidTaskDataException('Le numéro de la tâche est requis.');
    }
    final value = int.tryParse(args.first);
    if (value == null) {
      throw InvalidTaskDataException(
        'Numéro de tâche invalide: ${args.first}',
      );
    }
    return value - 1;
  }

  Priority _parsePriority(String? value) {
    if (value == null) return Priority.medium;
    try {
      return Priority.values.byName(value);
    } on ArgumentError {
      throw InvalidPriorityException('Priorité invalide: $value');
    }
  }

  TaskSort _parseSort(String? value) {
    switch (value) {
      case null:
        return TaskSort.none;
      case 'priority':
        return TaskSort.priority;
      case 'deadline':
      case 'date':
        return TaskSort.deadline;
      default:
        throw InvalidTaskDataException(
          'Tri invalide: $value (attendu priority ou deadline)',
        );
    }
  }

  DateTime? _parseDeadline(String? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } on FormatException {
      throw InvalidTaskDataException(
        'Date invalide: $value (attendu AAAA-MM-JJ)',
      );
    }
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  _ParsedOptions _parseOptions(List<String> args) {
    final positional = <String>[];
    final named = <String, String>{};
    final flags = <String>{};

    for (final arg in args) {
      if (arg.startsWith('--')) {
        final body = arg.substring(2);
        final eqIndex = body.indexOf('=');
        final name = eqIndex == -1 ? body : body.substring(0, eqIndex);
        if (name.isEmpty) {
          throw InvalidTaskDataException('Option invalide: "$arg"');
        }
        if (eqIndex == -1) {
          flags.add(name);
        } else {
          named[name] = body.substring(eqIndex + 1);
        }
      } else {
        positional.add(arg);
      }
    }

    return _ParsedOptions(positional: positional, named: named, flags: flags);
  }

  void _printHelp() {
    print('''
Gestionnaire de tâches en ligne de commande

Usage:
  task_manager_cli add <titre> [--priority=low|medium|high] [--deadline=AAAA-MM-JJ] [--urgent]
  task_manager_cli list [--done|--pending] [--priority=low|medium|high] [--sort=priority|deadline]
  task_manager_cli done <numéro>
  task_manager_cli remove <numéro>
  task_manager_cli help
''');
  }
}

class _ParsedOptions {
  final List<String> positional;
  final Map<String, String> named;
  final Set<String> flags;

  _ParsedOptions({
    required this.positional,
    required this.named,
    required this.flags,
  });
}
