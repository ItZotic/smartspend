import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal() {
    loadSettings(); // Load settings immediately when service is created
  }

  // --- State Variables ---
  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '₱';
  String _currencyName = 'Philippine Peso - PHP';
  String _currencyPosition = 'At start of amount';
  int _decimalPlaces = 2;

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get currencyName => _currencyName;
  String get currencyPosition => _currencyPosition;
  int get decimalPlaces => _decimalPlaces;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  String get currentThemeString {
    if (_themeMode == ThemeMode.light) return 'Light';
    if (_themeMode == ThemeMode.dark) return 'Dark';
    return 'System default';
  }

  // --- Setters & Persistence ---

  Future<void> setThemeMode(String mode) async {
    switch (mode) {
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'System default':
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
    _saveString('themeMode', mode);
  }

  Future<void> setCurrency(String name, String symbol) async {
    _currencyName = name;
    _currencySymbol = symbol;
    notifyListeners();
    _saveString('currencyName', name);
    _saveString('currencySymbol', symbol);
  }

  Future<void> setCurrencyPosition(String position) async {
    _currencyPosition = position;
    notifyListeners();
    _saveString('currencyPosition', position);
  }

  Future<void> setDecimalPlaces(int places) async {
    _decimalPlaces = places;
    notifyListeners();
    _saveInt('decimalPlaces', places);
  }

  // --- Formatting Helper ---
  String formatCurrency(double amount) {
    final NumberFormat formatter = NumberFormat.currency(
      decimalDigits: _decimalPlaces,
      symbol: '',
    );
    String formattedNumber = formatter.format(amount.abs());

    String result;
    if (_currencyPosition == 'At start of amount') {
      result = "$_currencySymbol$formattedNumber";
    } else if (_currencyPosition == 'At end of amount') {
      result = "$formattedNumber $_currencySymbol";
    } else {
      result = formattedNumber;
    }

    if (amount < 0) {
      return "-$result";
    }
    return result;
  }

  // --- Persistence Logic ---

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    String? theme = prefs.getString('themeMode');
    if (theme != null) {
      if (theme == 'Light') {
        _themeMode = ThemeMode.light;
      } else if (theme == 'Dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    // Load Currency
    _currencyName = prefs.getString('currencyName') ?? 'Philippine Peso - PHP';
    _currencySymbol = prefs.getString('currencySymbol') ?? '₱';
    _currencyPosition =
        prefs.getString('currencyPosition') ?? 'At start of amount';
    _decimalPlaces = prefs.getInt('decimalPlaces') ?? 2;

    notifyListeners();
  }

  // --- Color Palette ---
  Color get bgTop =>
      isDarkMode ? const Color(0xFF051C3F) : const Color(0xFFE3F2FD);
  Color get bgBottom =>
      isDarkMode ? const Color(0xFF031229) : const Color(0xFFF3F8FC);
  Color get cardBg => isDarkMode ? const Color(0xFF122545) : Colors.white;
  Color get textMain => isDarkMode ? Colors.white : const Color(0xFF102027);
  Color get textSub => isDarkMode ? Colors.white60 : Colors.grey.shade600;
  Color get primaryBlue => const Color(0xFF2979FF);
  Color get sheetColor =>
      isDarkMode ? const Color(0xFF0A1E3C) : const Color(0xFF051C3F);

  // --- World Currencies List ---
  final List<Map<String, String>> currencies = [
    {'name': 'US Dollar - USD', 'symbol': '\$'},
    {'name': 'Philippine Peso - PHP', 'symbol': '₱'},
    {'name': 'Euro - EUR', 'symbol': '€'},
    {'name': 'British Pound - GBP', 'symbol': '£'},
    {'name': 'Japanese Yen - JPY', 'symbol': '¥'},
    {'name': 'Indian Rupee - INR', 'symbol': '₹'},
    {'name': 'Australian Dollar - AUD', 'symbol': 'A\$'},
    {'name': 'Canadian Dollar - CAD', 'symbol': 'C\$'},
    {'name': 'Singapore Dollar - SGD', 'symbol': 'S\$'},
    {'name': 'Swiss Franc - CHF', 'symbol': 'CHF'},
    {'name': 'Malaysian Ringgit - MYR', 'symbol': 'RM'},
    {'name': 'Chinese Yuan - CNY', 'symbol': '¥'},
    {'name': 'New Zealand Dollar - NZD', 'symbol': 'NZ\$'},
    {'name': 'Thai Baht - THB', 'symbol': '฿'},
    {'name': 'Hong Kong Dollar - HKD', 'symbol': 'HK\$'},
    {'name': 'Mexican Peso - MXN', 'symbol': '\$'},
    {'name': 'Brazilian Real - BRL', 'symbol': 'R\$'},
    {'name': 'Indonesian Rupiah - IDR', 'symbol': 'Rp'},
    {'name': 'Turkish Lira - TRY', 'symbol': '₺'},
    {'name': 'Russian Ruble - RUB', 'symbol': '₽'},
    {'name': 'South Korean Won - KRW', 'symbol': '₩'},
    {'name': 'South African Rand - ZAR', 'symbol': 'R'},
    {'name': 'Nigerian Naira - NGN', 'symbol': '₦'},
    {'name': 'Vietnamese Dong - VND', 'symbol': '₫'},
  ];
}
