import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:tiny_pkce/src/exceptions.dart';
import 'package:tiny_pkce/src/oauth/oauth_requests.dart';
import 'package:tiny_pkce/src/oauth/oauth_token_result.dart';
import 'package:tiny_pkce/src/oauth/utils.dart';
import 'package:tiny_pkce/src/token_utils.dart';
import 'package:tiny_pkce_launcher/tiny_pkce_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// The current status of the [AuthService]
enum AuthServiceStatus {
  /// Initial state of the service
  loading,

  /// Logged in
  loggedIn,

  /// Logged out
  loggedOut,

  /// Error
  error,
}

// Preference keys for storing the tokens.
String _prefsAccessToken = 'auth_service_access_token';
String _prefsRefreshToken = 'auth_service_refresh_token';
String _prefsIdToken = 'auth_service_id_token';
String _prefsAccessTokenExpiry = 'auth_service_access_token_expiry';
String _prefsChallenge = 'auth_service_challenge';
String _prefsTokenUrl = 'auth_service_token_url';
String _prefsLoginTriggered = 'auth_service_login_triggered';

/// [AuthService] is used to handle authentication it automatically
///  refreshes tokens when needed.
class AuthService extends ChangeNotifier {
  /// Creates an [AuthService], the main class for handling authentication

  AuthService({
    required this.discoveryUrl,
    required this.clientId,
    required this.redirectUrl,
    required this.scopes,
    this.webRedirectUrl,
  });

  /// The discovery URL of the OAuth server
  final String discoveryUrl;

  /// The client ID
  final String clientId;

  /// The redirect URL
  final String redirectUrl;

  /// The web redirect URL
  final String? webRedirectUrl;

  /// The scopes
  final List<String> scopes;

  // Service status
  AuthServiceStatus _status = AuthServiceStatus.loading;

  final StreamController<AuthServiceStatus> _statusController =
      StreamController<AuthServiceStatus>.broadcast();

  /// Stream of the service status
  Stream<AuthServiceStatus> get statusStream => _statusController.stream;

  void _updateStatus(AuthServiceStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    notifyListeners();
  }

  /// The current status of the [AuthService]
  AuthServiceStatus get status => _status;

  final _storage = const FlutterSecureStorage();

  StreamSubscription<Uri>? _uriSubscription;

  /// Initializes the [AuthService] must be called before using the service

  Future<void> init() async {
    _status = AuthServiceStatus.loading;
    notifyListeners();

    _uriSubscription = AppLinks().uriLinkStream.listen(_onUri);

    if (await hasRefreshToken) {
      // Theres a refresh token. Since we are starting.
      // Fetch a new access token.
      await _refreshAccessToken();
    } else {
      // No refresh token. We are logged out.
      _status = AuthServiceStatus.loggedOut;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _uriSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onUri(Uri uri) async {
    debugPrint('uri: $uri');
    if (uri.queryParameters['code'] != null) {
      final code = uri.queryParameters['code']!;
      final rawChallenge = await _storage.read(key: _prefsChallenge);

      final loginTriggered = await _storage.read(key: _prefsLoginTriggered);

      final tokenUrl = await _storage.read(key: _prefsTokenUrl);

      if (loginTriggered == null || rawChallenge == null || tokenUrl == null) {
        throw LoginNotTriggeredException();
      }

      final timeDiff = DateTime.now().difference(
        DateTime.parse(loginTriggered),
      );

      if (timeDiff.inMinutes > 10) {
        throw LoginExpiredException();
      }

      try {
        final tokens = await fetchTokens(
          authCode: code,
          rawChallenge: rawChallenge,
          clientId: clientId,
          tokenUrl: tokenUrl,
          redirectUrl: webRedirectUrl ?? redirectUrl,
        );

        await _saveTokens(tokens);
        _updateStatus(AuthServiceStatus.loggedIn);
      } catch (e) {
        _updateStatus(AuthServiceStatus.error);
        rethrow;
      } finally {
        await _storage.delete(key: _prefsLoginTriggered);
        await _storage.delete(key: _prefsChallenge);
      }
    }
  }

  /// Whether there is a refresh token stored
  Future<bool> get hasRefreshToken async {
    return (await _storage.read(key: _prefsRefreshToken)) != null;
  }

  /// Whether the user is logged in
  bool get isLoggedIn => _status == AuthServiceStatus.loggedIn;

  /// Get the current refresh token
  Future<String?> get refreshToken => _storage.read(key: _prefsRefreshToken);

  /// Get the current access token, refreshes is if needed
  Future<String?> get accessToken async {
    if (await _shouldRefresh) {
      await _refreshAccessToken();
    }
    return _storage.read(key: _prefsAccessToken);
  }

  /// Get the current id token
  Future<String?> get idToken => _storage.read(key: _prefsIdToken);

  /// Return a map  of claims in the id token
  Future<Map<String, dynamic>?> get idClaims async {
    final token = await idToken;
    return token != null ? getTokenPayload(token) : null;
  }

  /// Return the DateTime when the access token expires
  Future<DateTime?> get accessTokenExpiresAt async {
    final expiry = await _storage.read(key: _prefsAccessTokenExpiry);
    if (expiry != null) {
      return DateTime.parse(expiry);
    }
    return null;
  }

  Future<bool> get _shouldRefresh async {
    // Refresh 1 minute early to compensate timing differences.
    const buffer = Duration(minutes: 1);
    final expiry = await accessTokenExpiresAt;
    return expiry != null && expiry.isBefore(DateTime.now().subtract(buffer));
  }

  /// Forces a refresh independent of the expiry time
  Future<void> forceRefresh() async {
    await _refreshAccessToken();
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await this.refreshToken;
    if (refreshToken == null) {
      throw Exception('No refresh token');
    }

    final result = await _getAccessToken(refreshToken);

    // Store the new tokens
    await _saveTokens(result);
    _updateStatus(AuthServiceStatus.loggedIn);
  }

  // Persist all tokens in a TokenResponse
  Future<void> _saveTokens(OAuthTokenResult response) async {
    // Delete old tokens
    await _storage.delete(key: _prefsAccessToken);
    await _storage.delete(key: _prefsAccessTokenExpiry);
    await _storage.write(key: _prefsAccessToken, value: response.accessToken);

    await _storage.write(
      key: _prefsAccessTokenExpiry,
      value: DateTime.now()
          .add(Duration(seconds: response.expiresIn))
          .toIso8601String(),
    );

    if (response.refreshToken != null) {
      await _storage.delete(key: _prefsRefreshToken);
      await _storage.write(
        key: _prefsRefreshToken,
        value: response.refreshToken,
      );
    }

    if (response.idToken != null) {
      await _storage.delete(key: _prefsIdToken);
      await _storage.write(key: _prefsIdToken, value: response.idToken);
    }
  }

  /// Try to log the user in. Returns a
  /// future bool whether the attempt was successful.
  Future<bool> launchLogin() async {
    final uri = await _buildLoginUri();

    // Handle ios and macos via the launcher plugin
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      final result = await TinyPkceLauncher().launchUrl(
        uri.toString(),
        redirectUrl.split(':').first,
      );

      await _onUri(Uri.parse(result!));
      return true;
    }

    return launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      webOnlyWindowName: '_self',
    );
  }

  /// Log the user out, deletes all tokens
  Future<void> logout() async {
    await _storage.delete(key: _prefsAccessToken);
    await _storage.delete(key: _prefsRefreshToken);
    await _storage.delete(key: _prefsIdToken);
    await _storage.delete(key: _prefsAccessTokenExpiry);
    _updateStatus(AuthServiceStatus.loggedOut);
  }

  Future<Uri> _buildLoginUri() async {
    final rawChallenge = generateChallenge();

    final challengeHash = base64UrlEncode(hashChallenge(rawChallenge));

    // Fetch the authorization URL
    final discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: discoveryUrl,
    );

    // Make sure the server supports the right code_challenge_methods_supported
    if (!discoveryResponse.codeChallengeMethodsSupported.contains('S256')) {
      throw UnsupportedCodeChallengeMethodException(
        'Server does not support S256 code_challenge_method.',
      );
    }

    // Store the challenge
    await _storage.write(key: _prefsChallenge, value: rawChallenge);
    await _storage.write(
      key: _prefsTokenUrl,
      value: discoveryResponse.tokenEndpoint,
    );
    await _storage.write(
      key: _prefsLoginTriggered,
      value: DateTime.now().toIso8601String(),
    );
    // Request the authorization URL

    final authUrl = discoveryResponse.authorizationEndpoint;

    final query = {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': webRedirectUrl ?? redirectUrl,
      'code_challenge': challengeHash,
      'code_challenge_method': 'S256',
      'prompt': 'login',
      'scope': scopes.join(' '),
    };

    // Get the auth url
    return Uri.parse(authUrl).replace(queryParameters: query);
  }

  Future<OAuthTokenResult> _getAccessToken(String refreshToken) async {
    final discoveryResponse = await getOAuthDiscoveryResponse(
      discoveryUrl: discoveryUrl,
    );

    final tokenUrl = discoveryResponse.tokenEndpoint;

    final query = {
      'client_id': clientId,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    };

    final url = Uri.parse(tokenUrl);

    final res = await post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: query,
    );

    if (res.statusCode != 200) {
      throw FailedToFetchTokensException(res.body);
    }

    return OAuthTokenResult.fromJson(
      json.decode(res.body) as Map<String, dynamic>,
    );
  }
}
