# task_manager_cli

Un gestionnaire de tâches en ligne de commande écrit en Dart pur (sans Flutter),
avec persistance locale au format JSON.

## Prérequis

- Dart SDK `^3.12.2`

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

Les tâches sont enregistrées dans `tasks.json`, créé dans le dossier courant
depuis lequel la commande est lancée (un fichier différent par dossier).

## Commandes

| Commande | Description |
|---|---|
| `add <titre> [--priority=low\|medium\|high] [--deadline=AAAA-MM-JJ] [--urgent]` | Ajoute une tâche. La priorité par défaut est `medium`. `--urgent` nécessite `--deadline`. |
| `list [--done\|--pending] [--priority=low\|medium\|high] [--sort=priority\|deadline]` | Affiche les tâches, avec filtres et tri optionnels. Sans `--sort`, l'ordre d'ajout est conservé. |
| `done <numéro>` | Marque la tâche `<numéro>` (celui affiché par `list`) comme terminée. |
| `remove <numéro>` | Supprime la tâche `<numéro>`. |
| `help` | Affiche l'aide. |

## Architecture

- [`lib/task.dart`](lib/task.dart) — `Task` (classe abstraite, implémente `Comparable<Task>`
  pour le tri par priorité), et ses deux sous-classes `SimpleTask` et `UrgentTask`.
- [`lib/repository.dart`](lib/repository.dart) — `Repository<T>`, un dépôt générique
  fichier/JSON (chargement, sauvegarde, ajout, suppression par index). `TaskRepository`
  en hérite et lui injecte la sérialisation de `Task` via son constructeur, plus la
  logique métier propre aux tâches (complétion, filtrage, tri).
- [`lib/app.dart`](lib/app.dart) — `App`, la couche CLI : analyse manuelle des
  arguments, dispatch vers le dépôt, formatage de la sortie.
- [`lib/exceptions.dart`](lib/exceptions.dart) — exceptions métier
  (`ItemNotFoundException`, `InvalidPriorityException`, `InvalidTaskDataException`,
  `StorageException`) levées en cas d'entrée ou de données invalides.

## Tests

```bash
dart test
```

- `test/task_test.dart` — sérialisation JSON, tri, gestion des données invalides.
- `test/repository_test.dart` — CRUD, filtrage, tri, persistance disque, fichier corrompu.
- `test/app_test.dart` — commandes CLI de bout en bout et codes de sortie.

## Intégration continue

Le workflow [`.github/workflows/dart.yml`](.github/workflows/dart.yml) exécute
`dart analyze` et `dart test` à chaque push et pull request sur `main`.
