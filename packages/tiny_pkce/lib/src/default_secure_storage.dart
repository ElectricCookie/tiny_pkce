import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tiny_pkce/src/secure_storage.dart';

/// Default implementation using FlutterSecureStorage
class DefaultSecureStorage implements SecureStorage {
  /// Creates a new [DefaultSecureStorage] with a default key prefix of ''.
  ///
  /// The [keyPrefix] is used to prefix all keys stored in the secure storage.
  /// This is useful to avoid conflicts with other keys stored in the secure
  /// storage.

  DefaultSecureStorage({String keyPrefix = ''}) : _keyPrefix = keyPrefix;

  final String _keyPrefix;

  final _storage = const FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String? value}) =>
      _storage.write(key: '$_keyPrefix$key', value: value);

  @override
  Future<String?> read({required String key}) =>
      _storage.read(key: '$_keyPrefix$key');

  @override
  Future<void> delete({required String key}) =>
      _storage.delete(key: '$_keyPrefix$key');
}
