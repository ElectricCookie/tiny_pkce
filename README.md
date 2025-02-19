# tiny_pkce 🔐

A lightweight Flutter package for implementing the OAuth 2.0 PKCE authentication flow. 🚀

## Features ✨

- **OAuth 2.0 PKCE Flow** 🔒: Securely implements the Proof Key for Code Exchange flow.
- **Automatic Token Refresh** 🔄: Seamlessly handles token refresh operations.
- **Secure Token Storage** 🗄️: Utilizes `flutter_secure_storage` for secure token management.
- **Cross-Platform Support** 📱: Compatible with iOS, macOS, and Web platforms.
- **Built-in URI Handling** 🔗: Manages OAuth redirects efficiently.
- **Real-time Status Updates** ⚡: Provides updates via Stream and ChangeNotifier.
- **Customizable** ⚙️: Allows configuration of scopes and endpoints.

## Getting Started

To use this package, add it to your `pubspec.yaml`.

### Basic Setup

1. **Initialize the AuthService** with your OAuth configuration:

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

   This setup aligns with the example in `main.dart`, ensuring consistency in configuration.

2. **Initialize the service** during your app's startup:

   ```dart
   await auth.init();
   ```

3. **Manage the authentication flow** within your UI:

   ```dart
   // To initiate login
   auth.launchLogin();

   // To log out
   auth.logout();

   // Listen for authentication status changes
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

   // Stream authentication status changes
   auth.statusStream.listen((status) {
     switch (status) {
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

---

© 2024 ElectricCookie

Licensed under the Apache License, Version 2.0. You may not use this file except in compliance with the License. Obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
