import 'dart:async';

/// Abstract class for storage operations
abstract class SecureStorage {
  /// Write a value to the storage
  Future<void> write({required String key, required String? value});

  /// Read a value from the storage
  Future<String?> read({required String key});

  /// Delete a value from the storage
  Future<void> delete({required String key});
}
