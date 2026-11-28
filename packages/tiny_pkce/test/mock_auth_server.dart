import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:tiny_pkce/src/oauth/oauth_discovery_response.dart';
import 'package:tiny_pkce/src/oauth/oauth_token_result.dart';

Future<HttpServer> launchMockAuthServer({
  OAuthTokenResult? tokenResult,
  List<String>? codeChallengeMethodsSupported,
}) async {
  final port = 8000 + Random().nextInt(1000);

  final app = Router()

    // Discovery endpoint
    ..get('/.well-known/openid-configuration', (Request request) {
      final discovery = OAuthDiscoveryResponse(
        authorizationEndpoint: 'http://localhost:$port/authorize',
        tokenEndpoint: 'http://localhost:$port/token',
        userinfoEndpoint: 'http://localhost:$port/userinfo',
        issuer: 'http://localhost:$port',
        jwksUri: 'http://localhost:$port/jwks',
        responseTypesSupported: ['code'],
        scopesSupported: ['openid', 'profile', 'email'],
        claimsSupported: ['sub', 'name', 'email'],
        subjectTypesSupported: ['public'],
        idTokenSigningAlgValuesSupported: ['RS256'],
        tokenEndpointAuthMethodsSupported: ['client_secret_basic'],
        codeChallengeMethodsSupported:
            codeChallengeMethodsSupported ?? ['S256'],
        grantTypesSupported: ['authorization_code', 'refresh_token'],
      );

      return Response.ok(
        jsonEncode(discovery.toJson()),
        headers: {'content-type': 'application/json'},
      );
    })

    // Authorization endpoint
    ..get('/authorize', (Request request) {
      final params = request.url.queryParameters;
      final redirectUri = params['redirect_uri'];
      final state = params['state'];

      if (redirectUri != null) {
        const code = 'mock_auth_code';
        final redirectUrl = Uri.parse(redirectUri).replace(
          queryParameters: {
            'code': code,
            if (state != null) 'state': state,
          },
        );

        return Response.found(redirectUrl.toString());
      }

      return Response.badRequest();
    })

    // Token endpoint
    ..post('/token', (Request request) async {
      final defaultTokenResult = OAuthTokenResult(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        idToken: 'mock_id_token',
        expiresIn: 3600,
        refreshTokenExpiresIn: 86400,
        scope: 'openid profile email',
        idTokenExpiresIn: 3600,
      );

      return Response.ok(
        jsonEncode(tokenResult?.toJson() ?? defaultTokenResult.toJson()),
        headers: {'content-type': 'application/json'},
      );
    });

  return serve(app.call, 'localhost', port);
}

/// Creates mock tokens with configurable expiry times
OAuthTokenResult createMockTokens({
  int accessTokenExpiresIn = 3600,
  int refreshTokenExpiresIn = 86400,
  int idTokenExpiresIn = 3600,
}) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final accessTokenPayload = {
    'exp': (now + accessTokenExpiresIn).toString(),
  };
  final refreshTokenPayload = {
    'exp': (now + refreshTokenExpiresIn).toString(),
  };
  final idTokenPayload = {
    'exp': (now + idTokenExpiresIn).toString(),
  };

  final accessToken = base64Encode(utf8.encode(jsonEncode(accessTokenPayload)));
  final refreshToken =
      base64Encode(utf8.encode(jsonEncode(refreshTokenPayload)));
  final idToken = base64Encode(utf8.encode(jsonEncode(idTokenPayload)));

  return OAuthTokenResult(
    accessToken: 'header.$accessToken.signature',
    refreshToken: 'header.$refreshToken.signature',
    idToken: 'header.$idToken.signature',
    expiresIn: accessTokenExpiresIn,
    refreshTokenExpiresIn: refreshTokenExpiresIn,
    scope: 'openid profile email',
    idTokenExpiresIn: idTokenExpiresIn,
  );
}
