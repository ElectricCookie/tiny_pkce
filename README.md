# tiny_pkce

A lightweight Flutter package for OAuth 2.0 PKCE authentication flow.

## Features

- Implements OAuth 2.0 PKCE (Proof Key for Code Exchange) flow
- Automatic token refresh handling
- Secure token storage using flutter_secure_storage
- Support for iOS, macOS and Web platforms
- Built-in URI handling for OAuth redirects
- Status updates via Stream and ChangeNotifier
- Customizable scopes and endpoints

## Getting Started

Add the package to your pubspec.yaml:

### Basic Setup

1. Initialize the AuthService with your OAuth configuration:

```dart
final auth = AuthService(
    discoveryUrl: 'https://your-auth-server/.well-known/openid-configuration',
    clientId: 'your_client_id',
    redirectUrl: 'your.app.scheme:/oauth/callback',
    scopes: ['openid', 'profile', 'email'],
    // Optional: For web platform
webRedirectUrl: "http://localhost:8080/login-callback",
);
```

2. Initialize the service in your app's startup:

```dart
await auth.init();
```

3. Handle the authentication flow in your UI:

```dart
// Login
auth.launchLogin();
// Logout
auth.logout();
// Listen to auth status changes
auth.addListener(() {
    switch (auth.status) {
        case AuthServiceStatus.loggedIn:
        // Handle logged in state
        break;
        case AuthServiceStatus.loggedOut:
        // Handle logged out state
        break;
        case AuthServiceStatus.loading:
        // Handle loading state
        break;
    }
});


// Access tokens and claims
final accessToken = await auth.accessToken;
final idToken = await auth.idToken;
final refreshToken = await auth.refreshToken;
final idClaims = await auth.idClaims;

```

Copyright 2024 @ElectricCookie

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
