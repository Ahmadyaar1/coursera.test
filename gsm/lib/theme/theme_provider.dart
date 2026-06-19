import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isNeonMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isNeonMode => _isNeonMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleNeonMode() {
    _isNeonMode = !_isNeonMode;
    notifyListeners();
  }

  Color getBackgroundColor() {
    if (_isNeonMode) return Colors.black;
    if (_isDarkMode) return Colors.grey[900]!;
    return Colors.grey[100]!;
  }

  Color getCardColor() {
    if (_isNeonMode) return const Color(0xFF0A0A0A);
    if (_isDarkMode) return Colors.grey[800]!;
    return Colors.white;
  }

  Color getPrimaryColor() {
    if (_isNeonMode) return const Color(0xFF00FF00);
    if (_isDarkMode) return Colors.blue[300]!;
    return Colors.blue;
  }

  Color getTextColor() {
    if (_isNeonMode) return const Color(0xFF00FF00);
    if (_isDarkMode) return Colors.white;
    return Colors.black;
  }

  Color getSecondaryTextColor() {
    if (_isNeonMode) return const Color(0xFF00FF00).withValues(alpha: 0.7);
    if (_isDarkMode) return Colors.grey[300]!;
    return Colors.grey[600]!;
  }

  TextStyle getTitleStyle() {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: getTextColor(),
      shadows: _isNeonMode ? [
        Shadow(
          blurRadius: 10,
          color: getPrimaryColor(),
        ),
      ] : null,
    );
  }

  BoxShadow getCardShadow() {
    if (_isNeonMode) {
      return BoxShadow(
        color: getPrimaryColor().withValues(alpha: 0.3),
        blurRadius: 15,
        spreadRadius: 1,
      );
    }
    return BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    );
  }
}