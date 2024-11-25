// Used to return the tokens to the caller

import 'package:json_annotation/json_annotation.dart';

part 'oauth_token_result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)

/// The result from the OAuth token endpoint
class OAuthTokenResult {
  /// Creates a new [OAuthTokenResult]
  OAuthTokenResult({
    this.expiresIn,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.refreshTokenExpiresIn,
    this.scope,
    this.idTokenExpiresIn,
  });

  /// Creates a new [OAuthTokenResult] from a JSON map
  factory OAuthTokenResult.fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenResultFromJson(json);

  /// Access token
  String? accessToken;

  /// Refresh token used to refresh the access token
  String? refreshToken;

  /// ID token (contains user info)
  String? idToken;

  /// The number of seconds until the access token expires
  int? expiresIn;

  /// Refresh token expiry
  int? refreshTokenExpiresIn;

  /// Scope
  String? scope;

  /// ID token expiry
  int? idTokenExpiresIn;
}
