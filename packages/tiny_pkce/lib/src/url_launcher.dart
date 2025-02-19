import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tiny_pkce_launcher/tiny_pkce_launcher.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// The url launcher interface, used to launch the auth flow
// ignore: one_member_abstracts
abstract class UrlLauncher {
  /// Launch the url, return the result, if possible otherwise null
  Future<String?> launchUrl(Uri url, String redirectScheme);
}

/// The default url launcher for running on real devices
class DefaultUrlLauncher extends UrlLauncher {
  @override
  Future<String?> launchUrl(Uri url, String redirectScheme) async {
    // Handle ios and macos via the launcher plugin
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      return TinyPkceLauncher().launchUrl(
        url.toString(),
        redirectScheme,
      );
    }

    final launched = await url_launcher.launchUrl(
      url,
      mode: url_launcher.LaunchMode.inAppBrowserView,
      webOnlyWindowName: '_self',
    );

    if (!launched) {
      throw Exception('Failed to launch url');
    }

    return url.toString();
  }
}
