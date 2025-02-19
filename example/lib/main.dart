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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _authStatusString {
    switch (auth.status) {
      case AuthServiceStatus.loading:
        return "Loading";
      case AuthServiceStatus.loggedIn:
        return "Logged in";
      case AuthServiceStatus.loggedOut:
        return "Logged out";
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
    }
  }

  void _copy(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    const snackBar = SnackBar(content: Text('Copied to clipboard'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
        stream: auth.statusStream,
        builder: (context, snapshot) {
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
            FutureBuilder(
                future: auth.accessTokenExpiresAt,
                builder: (context, snapshot) {
                  return ListTile(
                    title: const Text("Access token expires"),
                    subtitle:
                        Text(snapshot.data?.toIso8601String() ?? "Unknown"),
                  );
                }),
            ListTile(
              title: const Text("Force refresh"),
              trailing: const Icon(Icons.refresh),
              onTap: auth.forceRefresh,
            ),
            const Divider(),
            FutureBuilder(
                future: auth.accessToken,
                builder: (context, snapshot) {
                  return ListTile(
                    title: const Text("Access Token"),
                    subtitle: Text(snapshot.data?.substring(0, 16) ?? "null"),
                    onTap: () => _copy(snapshot.data ?? "null", context),
                    trailing: const Icon(Icons.copy),
                  );
                }),
            FutureBuilder(
                future: auth.refreshToken,
                builder: (context, snapshot) {
                  return ListTile(
                    title: const Text("Refresh Token"),
                    subtitle: Text(snapshot.data?.substring(0, 16) ?? "null"),
                    onTap: () => _copy(snapshot.data ?? "null", context),
                    trailing: const Icon(Icons.copy),
                  );
                }),
            FutureBuilder(
                future: auth.idToken,
                builder: (context, snapshot) {
                  return ListTile(
                    title: const Text("ID Token"),
                    subtitle: Text(snapshot.data?.substring(0, 16) ?? "null"),
                    onTap: () => _copy(snapshot.data ?? "null", context),
                    trailing: const Icon(Icons.copy),
                  );
                }),
            const Divider(),
            FutureBuilder(
                future: auth.idClaims,
                builder: (context, snapshot) {
                  return ListTile(
                    title: const Text("Claims"),
                    subtitle: Text(snapshot.data != null
                        ? jsonEncode(snapshot.data)
                        : "null"),
                  );
                }),
          ]);
        });
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
