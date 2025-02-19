import 'tiny_pkce_launcher_platform_interface.dart';

class TinyPkceLauncher {
  Future<String?> launchUrl(String url, String scheme) {
    return TinyPkceLauncherPlatform.instance.launchUrl(url, scheme);
  }
}
