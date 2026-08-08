import 'dart:io';

import 'package:task_manager_cli/task_manager_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String storagePath;
  late TaskRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('task_manager_cli_test_');
    storagePath = '${tempDir.path}/tasks.json';
    repository = TaskRepository(storagePath);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('starts empty when no file exists', () async {
    await repository.load();
    expect(repository.tasks, isEmpty);
  });

  test('add appends a task', () {
    repository.add(
      SimpleTask(title: 'Nouvelle tâche', priority: Priority.medium),
    );
    expect(repository.tasks, hasLength(1));
  });

  test('complete marks a task as done', () {
    repository.add(SimpleTask(title: 'Tâche', priority: Priority.medium));
    final task = repository.complete(0);
    expect(task.isDone, true);
    expect(repository.tasks.first.isDone, true);
  });

  test('complete throws for an invalid index', () {
    expect(
      () => repository.complete(5),
      throwsA(isA<ItemNotFoundException>()),
    );
  });

  test('removeAt removes the task and preserves the rest', () {
    repository.add(SimpleTask(title: 'A', priority: Priority.low));
    repository.add(SimpleTask(title: 'B', priority: Priority.low));
    final removed = repository.removeAt(0);
    expect(removed.title, 'A');
    expect(repository.tasks, hasLength(1));
    expect(repository.tasks.first.title, 'B');
  });

  test('list filters by completion state and priority', () {
    repository.add(
      SimpleTask(title: 'A', priority: Priority.low, isDone: true),
    );
    repository.add(SimpleTask(title: 'B', priority: Priority.high));
    repository.add(
      SimpleTask(title: 'C', priority: Priority.high, isDone: true),
    );

    final pending = repository.list(isDone: false);
    expect(pending.map((e) => e.value.title), ['B']);

    final highPriority = repository.list(priority: Priority.high);
    expect(highPriority.map((e) => e.value.title), ['B', 'C']);
  });

  test('list keeps original indices when sorted by priority', () {
    repository.add(SimpleTask(title: 'Basse', priority: Priority.low));
    repository.add(SimpleTask(title: 'Haute', priority: Priority.high));

    final sorted = repository.list(sort: TaskSort.priority);
    expect(sorted.first.value.title, 'Haute');
    expect(sorted.first.key, 1);
  });

  test('list can be sorted by deadline, tasks without one come last', () {
    repository.add(
      SimpleTask(title: 'Sans échéance', priority: Priority.medium),
    );
    repository.add(
      SimpleTask(
        title: 'Plus tard',
        priority: Priority.medium,
        deadline: DateTime(2026, 12, 1),
      ),
    );
    repository.add(
      SimpleTask(
        title: 'Bientôt',
        priority: Priority.medium,
        deadline: DateTime(2026, 8, 20),
      ),
    );

    final sorted = repository.list(sort: TaskSort.deadline);
    expect(sorted.map((e) => e.value.title), [
      'Bientôt',
      'Plus tard',
      'Sans échéance',
    ]);
  });

  test('save then load round-trips tasks to disk', () async {
    repository.add(SimpleTask(title: 'Persistée', priority: Priority.medium));
    repository.add(
      UrgentTask(
        title: 'Urgente',
        priority: Priority.high,
        deadline: DateTime(2026, 9, 1),
      ),
    );
    await repository.save();

    final reloaded = TaskRepository(storagePath);
    await reloaded.load();

    expect(reloaded.tasks, hasLength(2));
    expect(reloaded.tasks[0].title, 'Persistée');
    expect(reloaded.tasks[1], isA<UrgentTask>());
  });
}
