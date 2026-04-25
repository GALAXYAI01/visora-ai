import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userName;
  final String? error;
  final DateTime? sessionExpiry;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userName,
    this.error,
    this.sessionExpiry,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userName,
    String? error,
    DateTime? sessionExpiry,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    isLoading: isLoading ?? this.isLoading,
    userName: userName ?? this.userName,
    error: error,
    sessionExpiry: sessionExpiry ?? this.sessionExpiry,
  );

  bool get isSessionValid =>
      isAuthenticated && sessionExpiry != null && DateTime.now().isBefore(sessionExpiry!);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // Admin credentials (hashed) — in production, validate against backend
  static final _validCredentials = {
    'admin': EncryptionService.hashPassword('visora2024'),
    'shashank': EncryptionService.hashPassword('visora@admin'),
  };

  /// Attempt login with username/password
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Simulate network delay for realism
    await Future.delayed(const Duration(milliseconds: 800));

    final hashedInput = EncryptionService.hashPassword(password);
    final expectedHash = _validCredentials[username.toLowerCase()];

    if (expectedHash != null && hashedInput == expectedHash) {
      // 24-hour session
      final expiry = DateTime.now().add(const Duration(hours: 24));
      state = AuthState(
        isAuthenticated: true,
        userName: username,
        sessionExpiry: expiry,
      );

      // Persist encrypted session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_user', EncryptionService.encrypt(username));
      await prefs.setString('session_expiry', EncryptionService.encrypt(expiry.toIso8601String()));
      await prefs.setString('session_token', EncryptionService.encrypt('${username}_${expiry.millisecondsSinceEpoch}'));

      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid credentials. Please try again.',
      );
      return false;
    }
  }

  /// Restore session from encrypted SharedPreferences
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encUser = prefs.getString('session_user');
      final encExpiry = prefs.getString('session_expiry');

      if (encUser != null && encExpiry != null) {
        final user = EncryptionService.decrypt(encUser);
        final expiry = DateTime.parse(EncryptionService.decrypt(encExpiry));

        if (DateTime.now().isBefore(expiry)) {
          state = AuthState(
            isAuthenticated: true,
            userName: user,
            sessionExpiry: expiry,
          );
        } else {
          await _clearSession();
        }
      }
    } catch (_) {
      await _clearSession();
    }
  }

  /// Logout and wipe encrypted session data
  Future<void> logout() async {
    await _clearSession();
    state = const AuthState();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_user');
    await prefs.remove('session_expiry');
    await prefs.remove('session_token');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
