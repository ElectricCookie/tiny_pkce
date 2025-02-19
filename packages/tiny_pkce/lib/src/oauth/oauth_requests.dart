import 'dart:convert';

import 'package:http/http.dart';
import 'package:tiny_pkce/src/oauth/oauth_discovery_response.dart';
import 'package:tiny_pkce/src/oauth/oauth_token_result.dart';

/// gets the o auth configuration from the discovery endpoint
Future<OAuthDiscoveryResponse> getOAuthDiscoveryResponse({
  required String discoveryUrl,
}) async {
  final res = await get(Uri.parse(discoveryUrl));
  if (res.statusCode != 200) {
    throw Exception('Failed to fetch discovery document.');
  }

  return OAuthDiscoveryResponse.fromJson(
    json.decode(res.body) as Map<String, dynamic>,
  );
}

/// fetches the token with the code returned from the auth process
Future<OAuthTokenResult> fetchTokens({
  required String authCode,
  required String rawChallenge,
  required String clientId,
  required String tokenUrl,
  required String redirectUrl,
}) async {
  final query = {
    'client_id': clientId,
    'code': authCode,
    'redirect_uri': redirectUrl,
    'code_verifier': rawChallenge,
    'grant_type': 'authorization_code',
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
    throw Exception('Failed to fetch tokens. ${res.body}');
  }

  return OAuthTokenResult.fromJson(
    json.decode(res.body) as Map<String, dynamic>,
  );
}
