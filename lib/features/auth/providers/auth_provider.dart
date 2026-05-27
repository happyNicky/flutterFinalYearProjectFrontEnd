import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

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
  AuthNotifier() : super(AuthState()) {
    tryAutoLogin();
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

  Future<bool> loginWithOAuth(String provider) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    state = state.copyWith(
      isLoading: false,
      errorMessage:
          'OAuth login is disabled in app flow. Use email and password.',
    );
    return false;
  }

  Future<void> logout() async {
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
