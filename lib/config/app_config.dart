import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _spreadsheetKey = 'spreadsheet_id';
  static const String _fixedSpreadsheetId = '1v87EsPVkCkS02aU_p0D4VyM8rCAo2T2B1EwJcJDIvEA'; // Fixed spreadsheet ID

  static Future<void> setSpreadsheetId(String spreadsheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_spreadsheetKey, spreadsheetId);
  }

  static Future<String?> getSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_spreadsheetKey);
  }

  static Future<void> clearSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_spreadsheetKey);
  }

  static String get fixedSpreadsheetId => _fixedSpreadsheetId;
}
