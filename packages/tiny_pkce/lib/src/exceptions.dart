// ignore_for_file: public_member_api_docs

/// Exception thrown when the token is invalid
class InvalidTokenException implements Exception {
  InvalidTokenException(this.message);

  final String message;
}

/// Exception thrown when the tokens failed to fetch
class FailedToFetchTokensException implements Exception {
  FailedToFetchTokensException(this.message);

  final String message;
}

/// Exception thrown when we cant refresh the tokens
class FailedToRefreshTokensException implements Exception {
  FailedToRefreshTokensException(this.message);

  final String message;
}

// Thrown when the server is not suitable
class UnsupportedCodeChallengeMethodException implements Exception {
  UnsupportedCodeChallengeMethodException(this.message);

  final String message;
}

/// Exception thrown when the login expired
class LoginExpiredException implements Exception {}

/// Exception thrown when the login was not triggered
class LoginNotTriggeredException implements Exception {}
