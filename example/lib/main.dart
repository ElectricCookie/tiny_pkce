import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:tiny_pkce/tiny_pkce.dart';
import 'package:tiny_pkce_example/env.dart';

var auth = AuthService(
  discoveryUrl: discoveryUrl,
  clientId: clientId,
  redirectUrl: redirectUrl,
  scopes: scopes,
  webRedirectUrl: "http://localhost:8080/login-callback",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await auth.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiny PKCE Example',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      initialRoute: "/",
      onGenerateRoute: (settings) {
        if (settings.name?.contains("/login-callback") == true) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const LoginCallbackPage(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Tiny PKCE Example'),
              ),
              body: const AuthStatus()),
        );
      },
    );
  }
}

class AuthStatus extends StatefulWidget {
  const AuthStatus({super.key});

  @override
  State<AuthStatus> createState() => _AuthStatusState();
}

class _AuthStatusState extends State<AuthStatus> {
  String? _accesToken;
  String? _idToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  Map<String, dynamic>? _idClaims;

  @override
  void initState() {
    auth.addListener(_authChange);
    Future.delayed(Duration.zero, _authChange);
    super.initState();
  }

  @override
  void dispose() {
    auth.removeListener(_authChange);
    super.dispose();
  }

  void _authChange() async {
    // Plain re-render

    _accesToken = await auth.accessToken;
    _idToken = await auth.idToken;
    _expiresAt = await auth.accessTokenExpiresAt;
    _refreshToken = await auth.refreshToken;
    _idClaims = await auth.idClaims;

    setState(() {});
  }

  String get _authStatusString {
    switch (auth.status) {
      case AuthServiceStatus.loading:
        return "Loading";
      case AuthServiceStatus.loggedIn:
        return "Logged in";
      case AuthServiceStatus.loggedOut:
        return "Logged out";
      default:
        return "Unknown";
    }
  }

  Widget get _authAction {
    switch (auth.status) {
      case AuthServiceStatus.loading:
        return const CircularProgressIndicator();
      case AuthServiceStatus.loggedIn:
        return ListTile(
          title: const Text('Logout'),
          trailing: const Icon(Icons.logout),
          onTap: auth.logout,
        );
      case AuthServiceStatus.loggedOut:
        return ListTile(
          title: const Text('Login'),
          trailing: const Icon(Icons.login),
          onTap: auth.launchLogin,
        );
      default:
        return const Text('Unknown');
    }
  }

  void _copy(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    const snackBar = SnackBar(content: Text('Copied to clipboard'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    if (auth.status == AuthServiceStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(children: [
      ListTile(
        title: const Text('Auth status'),
        subtitle: Text(_authStatusString),
      ),
      AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 500,
          ),
          child: _authAction),
      const Divider(),
      ListTile(
        title: const Text("Access token expires"),
        subtitle: Text(_expiresAt?.toIso8601String() ?? "Unknown"),
      ),
      ListTile(
        title: const Text("Force refresh"),
        trailing: const Icon(Icons.refresh),
        onTap: auth.forceRefresh,
      ),
      const Divider(),
      ListTile(
          title: const Text("Access Token"),
          subtitle: Text(_accesToken?.substring(0, 16) ?? "null"),
          onTap: () => _copy(_accesToken ?? "null", context),
          trailing: const Icon(Icons.copy)),
      ListTile(
          title: const Text("Refresh Token"),
          subtitle: Text(_refreshToken?.substring(0, 16) ?? "null"),
          onTap: () => _copy(_refreshToken ?? "null", context),
          trailing: const Icon(Icons.copy)),
      ListTile(
          title: const Text("ID Token"),
          subtitle: Text(_idToken?.substring(0, 16) ?? "null"),
          onTap: () => _copy(_idToken ?? "null", context),
          trailing: const Icon(Icons.copy)),
      const Divider(),
      ListTile(
        title: const Text("Claims"),
        subtitle: Text(_idClaims != null ? jsonEncode(_idClaims) : "null"),
      ),
    ]);
  }
}

class LoginCallbackPage extends StatefulWidget {
  const LoginCallbackPage({super.key});

  @override
  State<LoginCallbackPage> createState() => _LoginCallbackPageState();
}

class _LoginCallbackPageState extends State<LoginCallbackPage> {
  @override
  void initState() {
    super.initState();
    _processLoginCallback();
  }

  void _processLoginCallback() async {
    await Future.delayed(Duration.zero);
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
