import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tiny_pkce_launcher_platform_interface.dart';

/// An implementation of [TinyPkceLauncherPlatform] that uses method channels.
class MethodChannelTinyPkceLauncher extends TinyPkceLauncherPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tiny_pkce_launcher');

  @override
  Future<String?> launchUrl(
    String url,
    String scheme, {
    bool? useEphemeralSession,
  }) async {
    final result = await methodChannel.invokeMethod<String>('launchUrl', {
      'url': url,
      'scheme': scheme,
      if (useEphemeralSession != null)
        'useEphemeralSession': useEphemeralSession,
    });
    return result;
  }
}
