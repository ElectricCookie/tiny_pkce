import 'package:tiny_pkce/src/url_launcher.dart';

class MockUrlLauncher extends UrlLauncher {
  String? lastUrl;

  @override
  Future<String?> launchUrl(
    Uri url,
    String redirectScheme, {
    bool? useEphemeralSession,
  }) async {
    lastUrl = url.toString();
    return null;
  }
}
