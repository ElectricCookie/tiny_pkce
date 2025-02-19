import 'package:tiny_pkce/src/secure_storage.dart';

class MockSecureStorage implements SecureStorage {
  final Map<String, String?> _storage = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  /// Clears all stored values
  void clear() {
    _storage.clear();
  }
}
