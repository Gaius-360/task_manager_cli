import 'package:task_manager_cli/task_manager_cli.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleTask', () {
    test('describe returns the title', () {
      final task = SimpleTask(
        title: 'Faire les courses',
        priority: Priority.medium,
      );
      expect(task.describe(), 'Faire les courses');
      expect(task.type, 'simple');
    });

    test('round-trips through JSON', () {
      final task = SimpleTask(
        title: 'Lire un livre',
        priority: Priority.low,
        deadline: DateTime(2026, 9, 1),
      );
      final decoded = Task.fromJson(task.toJson());
      expect(decoded, isA<SimpleTask>());
      expect(decoded.title, task.title);
      expect(decoded.priority, task.priority);
      expect(decoded.deadline, task.deadline);
    });
  });

  group('UrgentTask', () {
    test('describe is prefixed with URGENT', () {
      final task = UrgentTask(
        title: 'Payer la facture',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 10),
      );
      expect(task.describe(), 'URGENT: Payer la facture');
      expect(task.type, 'urgent');
    });

    test('round-trips through JSON', () {
      final task = UrgentTask(
        title: 'Appeler le médecin',
        priority: Priority.high,
        deadline: DateTime(2026, 8, 9),
        isDone: true,
      );
      final decoded = Task.fromJson(task.toJson());
      expect(decoded, isA<UrgentTask>());
      expect(decoded.isDone, true);
      expect(decoded.deadline, task.deadline);
    });
  });

  test('fromJson throws for an unknown type', () {
    expect(
      () => Task.fromJson({
        'type': 'inconnu',
        'title': 'x',
        'priority': 'low',
        'deadline': null,
        'isDone': false,
      }),
      throwsA(isA<InvalidTaskDataException>()),
    );
  });

  test('fromJson throws InvalidTaskDataException for malformed data', () {
    expect(
      () => Task.fromJson({'type': 'simple', 'title': 'x'}),
      throwsA(isA<InvalidTaskDataException>()),
    );
  });

  test('fromJson throws InvalidTaskDataException for an unknown priority', () {
    expect(
      () => Task.fromJson({
        'type': 'simple',
        'title': 'x',
        'priority': 'urgentissime',
        'deadline': null,
        'isDone': false,
      }),
      throwsA(isA<InvalidTaskDataException>()),
    );
  });

  test('compareTo orders by priority, highest first', () {
    final low = SimpleTask(title: 'Basse', priority: Priority.low);
    final high = SimpleTask(title: 'Haute', priority: Priority.high);
    final tasks = [low, high]..sort();
    expect(tasks.first, high);
  });
}
