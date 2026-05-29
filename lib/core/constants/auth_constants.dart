
class AuthConstants {
  
  static const String googleClientId =
      '387899639418-a9jsdmuis71ciqvu7buaf0iktq2g6usu.apps.googleusercontent.com';

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: googleClientId,
  );

  static const String googleAuthPath = '/api/auth/google';
}
