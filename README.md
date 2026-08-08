# task_manager_cli

Un gestionnaire de tâches en ligne de commande écrit en Dart.

## Installation

```bash
dart pub get
```

## Utilisation

```bash
dart run bin/task_manager_cli.dart add "Faire les courses" --priority=high
dart run bin/task_manager_cli.dart add "Payer la facture" --urgent --deadline=2026-08-15
dart run bin/task_manager_cli.dart list
dart run bin/task_manager_cli.dart done 1
dart run bin/task_manager_cli.dart remove 2
```

Les tâches sont enregistrées dans `tasks.json`, créé dans le dossier courant.

## Commandes

- `add <titre> [--priority=low|medium|high] [--deadline=AAAA-MM-JJ] [--urgent]`
  ajoute une tâche. `--urgent` nécessite une échéance.
- `list [--done|--pending] [--priority=low|medium|high] [--sort=priority|deadline]`
  affiche les tâches, avec filtres et tri optionnel par priorité ou par échéance.
- `done <numéro>` marque une tâche comme terminée.
- `remove <numéro>` supprime une tâche.
- `help` affiche l'aide.

## Tests

```bash
dart test
```
