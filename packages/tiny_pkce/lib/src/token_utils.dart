import 'dart:convert';

import 'package:tiny_pkce/src/exceptions.dart';

/// [getTokenPayload] returns the payload of a JWT token
Map<String, dynamic>? getTokenPayload(String token) {
  final split = token.split('.');
  if (split.length != 3) {
    throw InvalidTokenException('Invalid token');
  }
  final payload = split[1];
  final decoded = _decodeBase64(payload);
  final json = jsonDecode(decoded);
  return json as Map<String, dynamic>;
}

String _decodeBase64(String str) {
  var output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
    case 3:
      output += '=';
    default:
      throw InvalidTokenException('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}
