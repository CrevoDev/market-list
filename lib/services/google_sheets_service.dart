import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';
import '../maps/shopping_item.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class GoogleSheetsService {
  final GSheets _gsheets;
  late String _spreadsheetId;

  GoogleSheetsService(String credentials, this._spreadsheetId) : _gsheets = GSheets(credentials);

  static Future<GoogleSheetsService> initialize() async {
    // Carregue o arquivo JSON de credenciais
    final credentials = await rootBundle.loadString('assets/credentials.json');
    final spreadsheetId = await AppConfig.getSpreadsheetId() ?? AppConfig.fixedSpreadsheetId;
    return GoogleSheetsService(credentials, spreadsheetId);
  }

  Future<List<String>> getShoppingLists() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLists = prefs.getStringList('shoppingLists');
    if (cachedLists != null) {
      return cachedLists;
    }

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final lists = ss.sheets.skip(1).map((sheet) => sheet.title).toList();
    await prefs.setStringList('shoppingLists', lists);
    return lists;
  }

  Future<List<ShoppingItem>> getItems(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('items_$listName');
    if (cachedItems != null) {
      final List<dynamic> decodedItems = jsonDecode(cachedItems);
      final items = decodedItems.map((item) => ShoppingItem.fromJson(item)).toList();
      final ss = await _gsheets.spreadsheet(_spreadsheetId);
      final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
      final rows = await sheet.values.allRows();
      final existingIds = rows.map((row) => row[0]).toSet();
      final nonDuplicateItems = items.where((item) => !existingIds.contains(item.id)).toList();
      return nonDuplicateItems;
    }

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    final rows = await sheet.values.allRows();
    if (rows.isEmpty) return [];
    final items = rows.map((row) {
      return ShoppingItem(row[0], row[1], num.parse(row[2]), double.parse(row[3].replaceAll(',', '.')), row[4] == 'true');
    }).toList();
    await prefs.setString('items_$listName', jsonEncode(items));
    return items;
  }

  Future<void> addList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLists = prefs.getStringList('shoppingLists') ?? [];
    cachedLists.add(listName);
    await prefs.setStringList('shoppingLists', cachedLists);

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    await ss.addWorksheet(listName);
  }

  Future<void> addItem(String listName, ShoppingItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('items_$listName');
    final List<dynamic> items = cachedItems != null ? jsonDecode(cachedItems) : [];
    items.add(item.toJson());
    await prefs.setString('items_$listName', jsonEncode(items));

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    await sheet.values.appendRow([item.id, item.name, item.unit.toString(), item.value.toString().replaceAll('.', ','), item.isChecked.toString()]);
  }

  Future<void> updateItem(String listName, ShoppingItem newItem) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('items_$listName');
    final List<dynamic> items = cachedItems != null ? jsonDecode(cachedItems) : [];
    final index = items.indexWhere((item) => ShoppingItem.fromJson(item).id == newItem.id);
    if (index != -1) {
      items[index] = newItem.toJson();
      await prefs.setString('items_$listName', jsonEncode(items));
    }

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    final rows = await sheet.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == newItem.id);
    if (rowIndex != -1) {
      await sheet.values.insertRow(rowIndex + 1, [newItem.id, newItem.name, newItem.unit.toString(), newItem.value.toString().replaceAll('.', ','), newItem.isChecked.toString()]);
    }
  }

  Future<void> updateItemChecked(String listName, String itemId, bool isChecked) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('items_$listName');
    final List<dynamic> items = cachedItems != null ? jsonDecode(cachedItems) : [];
    final index = items.indexWhere((i) => ShoppingItem.fromJson(i).id == itemId);
    if (index != -1) {
      items[index]['isChecked'] = isChecked;
      await prefs.setString('items_$listName', jsonEncode(items));
    }

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    final rows = await sheet.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == itemId);
    if (rowIndex != -1) {
      await sheet.values.insertRow(rowIndex + 1, [itemId, rows[rowIndex][1], rows[rowIndex][2], rows[rowIndex][3].replaceAll('.', ','), isChecked.toString()]);
    }
  }

  Future<void> updateListName(String oldName, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLists = prefs.getStringList('shoppingLists') ?? [];
    final index = cachedLists.indexOf(oldName);
    if (index != -1) {
      cachedLists[index] = newName;
      await prefs.setStringList('shoppingLists', cachedLists);
    }

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == oldName);
    await sheet.updateTitle(newName);
  }

  Future<void> removeList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLists = prefs.getStringList('shoppingLists') ?? [];
    cachedLists.remove(listName);
    await prefs.setStringList('shoppingLists', cachedLists);

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    await ss.deleteWorksheet(sheet);
  }

  Future<void> removeItem(String listName, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('items_$listName');
    final List<dynamic> items = cachedItems != null ? jsonDecode(cachedItems) : [];
    items.removeWhere((i) => ShoppingItem.fromJson(i).id == itemId);
    await prefs.setString('items_$listName', jsonEncode(items));

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    final rows = await sheet.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == itemId);
    if (rowIndex != -1) {
      await sheet.deleteRow(rowIndex + 1);
    }
  }

  Future<void> selectAllItems(String listName, bool isChecked) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedItems = prefs.getString('items_$listName');
    final List<dynamic> items = cachedItems != null ? jsonDecode(cachedItems) : [];
    for (var item in items) {
      item['isChecked'] = isChecked;
    }
    await prefs.setString('items_$listName', jsonEncode(items));

    final ss = await _gsheets.spreadsheet(_spreadsheetId);
    final sheet = ss.sheets.firstWhere((sheet) => sheet.title == listName);
    final rows = await sheet.values.allRows();
    for (var row in rows) {
      row[4] = isChecked.toString();
    }
    await sheet.values.insertRows(1, rows.map((row) => row.cast<dynamic>()).toList());
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shoppingLists');
    final keys = prefs.getKeys().where((key) => key.startsWith('items_')).toList();
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
