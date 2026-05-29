import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/auth_constants.dart';

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final String? token;
  final String? email;
  final String? name;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.token,
    this.email,
    this.name,
    this.errorMessage,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    String? token,
    String? email,
    String? name,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      token: token ?? this.token,
      email: email ?? this.email,
      name: name ?? this.name,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  GoogleSignIn? _googleSignIn;

  AuthNotifier() : super(AuthState()) {
    tryAutoLogin();
  }

  GoogleSignIn get _google {
    _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: AuthConstants.googleServerClientId,
    );
    return _googleSignIn!;
  }

  Future<void> tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('auth_email');
    final name = prefs.getString('auth_name');

    if (token != null) {
      state = AuthState(
        token: token,
        email: email,
        name: name,
        isInitialized: true,
      );
    } else {
      state = AuthState(isInitialized: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = _extractErrorMessage(response.body) ?? 'Login failed.';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token']?.toString();
      final userEmail = data['email']?.toString() ?? email;
      final userName = data['name']?.toString() ?? userEmail.split('@').first;

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed: missing token.',
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_email', userEmail);
      await prefs.setString('auth_name', userName);

      state = AuthState(
        token: token,
        email: userEmail,
        name: userName,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = _extractErrorMessage(response.body) ?? 'Registration failed.';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token']?.toString();
      final userEmail = data['email']?.toString() ?? email;
      final userName = data['name']?.toString() ?? name;

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Registration failed: missing token.',
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_email', userEmail);
      await prefs.setString('auth_name', userName);

      state = AuthState(
        token: token,
        email: userEmail,
        name: userName,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _google.signOut();

      final account = await _google.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Could not get a Google ID token. In Google Cloud, add an Android OAuth client for package com.example.flutter_news_app with your debug SHA-1.',
        );
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${AuthConstants.googleAuthPath}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = _extractErrorMessage(response.body) ??
            'Google sign-in failed (${response.statusCode}). Check that the backend is running and API_BASE_URL is correct.';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token']?.toString();
      final userEmail =
          data['email']?.toString() ?? account.email ?? 'user@google.com';
      final userName = data['name']?.toString() ??
          account.displayName ??
          userEmail.split('@').first;

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Google sign-in failed: missing token from server.',
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_email', userEmail);
      await prefs.setString('auth_name', userName);

      state = AuthState(
        token: token,
        email: userEmail,
        name: userName,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _googleSignInErrorMessage(e),
      );
      return false;
    }
  }

  String _googleSignInErrorMessage(Object e) {
    final text = e.toString();
    if (text.contains('ApiException: 10')) {
      return 'Google Sign-In setup error (code 10). In Google Cloud Console, create an Android OAuth client with package name com.example.flutter_news_app and your debug SHA-1 fingerprint.';
    }
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return 'Cannot reach the backend. For local dev, start Spring Boot on port 8080. For production, set API_BASE_URL to your Railway domain.';
    }
    return 'Google sign-in failed: $text';
  }

  Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    state = AuthState(isInitialized: true);
  }

  String? _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
      }
    } catch (_) {}
    return null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
