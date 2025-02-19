import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_pkce/src/auth_service.dart';
import 'package:tiny_pkce/src/exceptions.dart';

import 'mock_auth_server.dart';
import 'mock_secure_storage.dart';
import 'mock_url_launcher.dart';

void main() {
  late HttpServer server;
  late AuthService authService;
  late String discoveryUrl;
  late MockSecureStorage mockStorage;
  late StreamController<Uri> uriStreamController;
  late MockUrlLauncher mockUrlLauncher;

  setUp(() async {
    mockStorage = MockSecureStorage();
    mockUrlLauncher = MockUrlLauncher();
    server = await launchMockAuthServer();
    uriStreamController = StreamController<Uri>.broadcast();
    final port = server.port;
    discoveryUrl = 'http://localhost:$port/.well-known/openid-configuration';

    authService = AuthService(
      discoveryUrl: discoveryUrl,
      clientId: 'test_client',
      redirectUrl: 'com.example.app://callback',
      scopes: ['openid', 'profile', 'email'],
      storage: mockStorage,
      uriStream: uriStreamController.stream,
      urlLauncher: mockUrlLauncher,
    );
  });

  tearDown(() async {
    await server.close();
    authService.dispose();
    mockStorage.clear();
    await uriStreamController.close();
  });

  test('initializes with logged out status when no tokens present', () async {
    await authService.init();
    expect(authService.status, equals(AuthServiceStatus.loggedOut));
  });

  test('validates code challenge methods from discovery endpoint', () async {
    final service = AuthService(
      clientId: 'test_client',
      redirectUrl: 'com.example.app://callback',
      scopes: ['openid'],
      discoveryUrl: discoveryUrl,
      storage: mockStorage,
      uriStream: uriStreamController.stream,
      urlLauncher: mockUrlLauncher,
    );

    await service.launchLogin();
  });

  test('handles expired tokens correctly', () async {
    final expiredTokens = createMockTokens(
      accessTokenExpiresIn: -3600,
    );

    server = await launchMockAuthServer(tokenResult: expiredTokens);

    final service = AuthService(
      clientId: 'test_client',
      redirectUrl: 'com.example.app://callback',
      scopes: ['openid'],
      discoveryUrl: discoveryUrl,
      storage: mockStorage,
      uriStream: uriStreamController.stream,
      urlLauncher: mockUrlLauncher,
    );

    await service.init();
    expect(await service.hasRefreshToken, isFalse);
  });

  test('refreshes access token when expired', () async {
    final tokensWithExpired = createMockTokens(
      accessTokenExpiresIn: -60,
      refreshTokenExpiresIn: 3600,
    );

    final tokens = createMockTokens(
      refreshTokenExpiresIn: 3600,
    );

    await mockStorage.write(
      key: 'auth_service_access_token',
      value: tokensWithExpired.accessToken,
    );
    await mockStorage.write(
      key: 'auth_service_refresh_token',
      value: tokensWithExpired.refreshToken,
    );
    await mockStorage.write(
      key: 'auth_service_access_token_expiry',
      value: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    );

    server = await launchMockAuthServer(
      tokenResult: tokens,
    );

    final service = AuthService(
      clientId: 'test_client',
      redirectUrl: 'com.example.app://callback',
      scopes: ['openid'],
      discoveryUrl: discoveryUrl,
      storage: mockStorage,
      uriStream: uriStreamController.stream,
      urlLauncher: mockUrlLauncher,
    );

    await service.init();
    expect(await service.accessToken, isNotNull);
  });

  test('throws exception when refresh token is expired', () async {
    final tokens = createMockTokens(
      refreshTokenExpiresIn: -3600,
    );

    server = await launchMockAuthServer(tokenResult: tokens);

    final service = AuthService(
      clientId: 'test_client',
      redirectUrl: 'com.example.app://callback',
      scopes: ['openid'],
      discoveryUrl: discoveryUrl,
      storage: mockStorage,
      uriStream: uriStreamController.stream,
      urlLauncher: mockUrlLauncher,
    );

    await service.init();
    expect(service.forceRefresh(), throwsA(isA<Exception>()));
  });

  test('handles login flow correctly', () async {
    await authService.launchLogin();
    final uri = mockUrlLauncher.lastUrl;
    expect(uri.toString(), contains('code_challenge'));
    expect(uri.toString(), contains('code_challenge_method=S256'));
  });

  test('throws when code challenge validation fails', () async {
    await server.close();

    server = await launchMockAuthServer(
      codeChallengeMethodsSupported: ['none'],
    );

    final discoveryUrl =
        'http://localhost:${server.port}/.well-known/openid-configuration';

    final service = AuthService(
      clientId: 'test_client',
      redirectUrl: 'com.example.app://callback',
      scopes: ['openid'],
      discoveryUrl: discoveryUrl,
      storage: mockStorage,
      uriStream: uriStreamController.stream,
      urlLauncher: mockUrlLauncher,
    );

    expect(
      service.launchLogin(),
      throwsA(isA<UnsupportedCodeChallengeMethodException>()),
    );
  });
}
