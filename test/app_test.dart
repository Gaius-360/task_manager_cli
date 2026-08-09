import 'dart:io';

import 'package:task_manager_cli/task_manager_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late TaskRepository repository;
  late App app;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'task_manager_cli_app_test_',
    );
    repository = TaskRepository('${tempDir.path}/tasks.json');
    app = App(repository);
    exitCode = 0;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    exitCode = 0;
  });

  test('add creates a simple task with the default priority', () async {
    await app.run(['add', 'Faire', 'les', 'courses']);

    expect(repository.items, hasLength(1));
    final task = repository.items.first;
    expect(task, isA<SimpleTask>());
    expect(task.title, 'Faire les courses');
    expect(task.priority, Priority.medium);
    expect(exitCode, 0);
  });

  test('add --urgent without a deadline fails and adds nothing', () async {
    await app.run(['add', 'Urgent', '--urgent']);

    expect(repository.items, isEmpty);
    expect(exitCode, 1);
  });

  test('add persists the task to disk', () async {
    await app.run(['add', 'Tâche persistée', '--priority=high']);

    final reloaded = TaskRepository(repository.storagePath);
    await reloaded.load();
    expect(reloaded.items, hasLength(1));
    expect(reloaded.items.first.priority, Priority.high);
  });

  test('done marks the referenced task as complete', () async {
    await app.run(['add', 'Tâche']);
    await app.run(['done', '1']);

    expect(repository.items.first.isDone, true);
  });

  test('done fails with an invalid index', () async {
    await app.run(['done', '99']);
    expect(exitCode, 1);
  });

  test('remove deletes the referenced task', () async {
    await app.run(['add', 'A']);
    await app.run(['add', 'B']);
    await app.run(['remove', '1']);

    expect(repository.items, hasLength(1));
    expect(repository.items.first.title, 'B');
  });

  test('an unknown command sets a non-zero exit code', () async {
    await app.run(['frobnicate']);
    expect(exitCode, 64);
  });

  test('list with an invalid --sort value fails', () async {
    await app.run(['add', 'Tâche']);
    await app.run(['list', '--sort=invalid']);

    expect(exitCode, 1);
  });

  test('a malformed option name is rejected', () async {
    await app.run(['add', 'Tâche', '--=oops']);
    expect(repository.items, isEmpty);
    expect(exitCode, 1);
  });
}
