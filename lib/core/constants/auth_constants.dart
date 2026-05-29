/// Google Sign-In — OAuth client from Google Cloud (project flutterfinalyearproject-497519).
class AuthConstants {
  /// Android / installed OAuth client ID (from your credentials JSON).
  static const String googleClientId =
      '387899639418-a9jsdmuis71ciqvu7buaf0iktq2g6usu.apps.googleusercontent.com';

  /// Passed to [GoogleSignIn] as serverClientId so the app receives an ID token for the backend.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: googleClientId,
  );

  static const String googleAuthPath = '/api/auth/google';
}
