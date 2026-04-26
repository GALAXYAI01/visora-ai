import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings state
class AppSettings {
  final ThemeMode themeMode;
  final bool notifications;
  final bool autoScan;
  final bool analytics;
  final String language;

  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.notifications = true,
    this.autoScan = true,
    this.analytics = false,
    this.language = 'English',
  });

  bool get isDark => themeMode == ThemeMode.dark;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notifications,
    bool? autoScan,
    bool? analytics,
    String? language,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    notifications: notifications ?? this.notifications,
    autoScan: autoScan ?? this.autoScan,
    analytics: analytics ?? this.analytics,
    language: language ?? this.language,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      themeMode: (prefs.getBool('dark_mode') ?? false) ? ThemeMode.dark : ThemeMode.light,
      notifications: prefs.getBool('notifications') ?? true,
      autoScan: prefs.getBool('auto_scan') ?? true,
      analytics: prefs.getBool('analytics') ?? false,
      language: prefs.getString('language') ?? 'English',
    );
  }

  Future<void> toggleDarkMode(bool on) async {
    state = state.copyWith(themeMode: on ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', on);
  }

  Future<void> setNotifications(bool v) async {
    state = state.copyWith(notifications: v);
    (await SharedPreferences.getInstance()).setBool('notifications', v);
  }

  Future<void> setAutoScan(bool v) async {
    state = state.copyWith(autoScan: v);
    (await SharedPreferences.getInstance()).setBool('auto_scan', v);
  }

  Future<void> setAnalytics(bool v) async {
    state = state.copyWith(analytics: v);
    (await SharedPreferences.getInstance()).setBool('analytics', v);
  }

  Future<void> setLanguage(String v) async {
    state = state.copyWith(language: v);
    (await SharedPreferences.getInstance()).setString('language', v);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
