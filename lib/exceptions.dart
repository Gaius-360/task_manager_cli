class ItemNotFoundException implements Exception {
  final String message;
  ItemNotFoundException(this.message);

  @override
  String toString() => 'ItemNotFoundException: $message';
}

class InvalidPriorityException implements Exception {
  final String message;
  InvalidPriorityException(this.message);

  @override
  String toString() => 'InvalidPriorityException: $message';
}

class InvalidTaskDataException implements Exception {
  final String message;
  InvalidTaskDataException(this.message);

  @override
  String toString() => 'InvalidTaskDataException: $message';
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}