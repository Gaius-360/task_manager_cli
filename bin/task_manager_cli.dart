import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:task_manager_cli/task_manager_cli.dart';

Future<void> main(List<String> arguments) async {
  final storagePath = p.join(Directory.current.path, 'tasks.json');
  final repository = TaskRepository(storagePath);
  await repository.load();
  final app = App(repository);
  await app.run(arguments);
}
