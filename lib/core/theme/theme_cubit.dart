import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themeKey = 'app_theme_mode';
  final SharedPreferences prefs;

  ThemeCubit({required this.prefs}) : super(_getInitialTheme(prefs));

  static ThemeMode _getInitialTheme(SharedPreferences prefs) {
    final isDark = prefs.getBool(_themeKey) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    prefs.setBool(_themeKey, newMode == ThemeMode.dark);
    emit(newMode);
  }
}
