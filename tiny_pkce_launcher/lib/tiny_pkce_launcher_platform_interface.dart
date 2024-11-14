import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tiny_pkce_launcher_method_channel.dart';

abstract class TinyPkceLauncherPlatform extends PlatformInterface {
  /// Constructs a TinyPkceLauncherPlatform.
  TinyPkceLauncherPlatform() : super(token: _token);

  static final Object _token = Object();

  static TinyPkceLauncherPlatform _instance = MethodChannelTinyPkceLauncher();

  /// The default instance of [TinyPkceLauncherPlatform] to use.
  ///
  /// Defaults to [MethodChannelTinyPkceLauncher].
  static TinyPkceLauncherPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TinyPkceLauncherPlatform] when
  /// they register themselves.
  static set instance(TinyPkceLauncherPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> launchUrl(String url, String scheme) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
