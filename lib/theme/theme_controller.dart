import 'package:flutter/material.dart';

/// Controlador de tema do aplicativo.
///
/// Gerencia o [ThemeMode] atual e notifica ouvintes quando ele muda.
/// Isso permite que o [MaterialApp] reconstrua com o novo tema.
class ThemeController extends ChangeNotifier {
  /// Modo de tema atual. Começa seguindo o sistema.
  ThemeMode _mode = ThemeMode.system;

  /// Retorna o modo de tema atual.
  ThemeMode get mode => _mode;

  /// Retorna true se o modo atual é escuro.
  bool get isDarkMode => _mode == ThemeMode.dark;

  /// Retorna true se o modo atual segue o sistema.
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Altera o modo de tema e notifica os ouvintes.
  void setMode(ThemeMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  /// Alterna entre claro e escuro.
  ///
  /// Se estiver em modo sistema, detecta o tema atual e inverte.
  void toggle(Brightness currentBrightness) {
    if (_mode == ThemeMode.system) {
      // Se estava em sistema, vai para o oposto do atual
      _mode = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    } else {
      // Alterna entre claro e escuro
      _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }
}
