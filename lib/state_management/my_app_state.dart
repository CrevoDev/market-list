import 'dart:convert';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/interfaces/i_response.dart';
import '../maps/shopping_item.dart';
import '../services/google_sheets_service.dart';
import '../services/gemini_api_service.dart';

class MyAppState extends ChangeNotifier {
  final GoogleSheetsService googleSheetsService;
  final GeminiApiService geminiApiService = GeminiApiService();
  var current = WordPair.random();
  var shoppingLists = <String, List<ShoppingItem>>{};

  MyAppState(this.googleSheetsService) {
    _initializeLists();
  }

  Future<void> _initializeLists() async {
    final lists = await googleSheetsService.getShoppingLists();
    for (var list in lists) {
      shoppingLists[list] = await googleSheetsService.getItems(list);
    }
    notifyListeners();
  }

  Future<void> addList(String listName) async {
    if (!shoppingLists.containsKey(listName)) {
      shoppingLists[listName] = [];
      await googleSheetsService.addList(listName);
      notifyListeners();
    }
  }

  Future<void> addItem(String listName, ShoppingItem item) async {
    shoppingLists[listName]?.add(item);
    await googleSheetsService.addItem(listName, item);
    notifyListeners();
  }

  Future<void> updateItem(String listName, ShoppingItem newItem) async {
    final list = shoppingLists[listName];
    if (list != null) {
      final index = list.indexWhere((item) => item.id == newItem.id);
      if (index != -1) {
        list[index] = newItem;
        await googleSheetsService.updateItem(listName, newItem);
        notifyListeners();
      }
    }
  }

  Future<void> updateItemChecked(
      String listName, String itemId, bool isChecked) async {
    final list = shoppingLists[listName];
    if (list != null) {
      final index = list.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        list[index].isChecked = isChecked;
        await googleSheetsService.updateItemChecked(
            listName, itemId, isChecked);
        notifyListeners();
      }
    }
  }

  Future<void> updateListName(String oldName, String newName) async {
    if (shoppingLists.containsKey(oldName) &&
        !shoppingLists.containsKey(newName)) {
      final items = shoppingLists.remove(oldName);
      shoppingLists[newName] = items!;
      await googleSheetsService.updateListName(oldName, newName);
      notifyListeners();
    }
  }

  Future<void> removeList(String listName) async {
    shoppingLists.remove(listName);
    await googleSheetsService.removeList(listName);
    notifyListeners();
  }

  Future<void> removeItem(String listName, String itemId) async {
    final list = shoppingLists[listName];
    if (list != null) {
      list.removeWhere((item) => item.id == itemId);
      await googleSheetsService.removeItem(listName, itemId);
      notifyListeners();
    }
  }

  Future<void> selectAllItems(String listName, bool isChecked) async {
    final list = shoppingLists[listName];
    if (list != null) {
      for (var item in list) {
        item.isChecked = isChecked;
      }
      await googleSheetsService.selectAllItems(listName, isChecked);
      notifyListeners();
    }
  }

  Future<void> refreshCache() async {
    await googleSheetsService.clearCache();
    await _initializeLists();
  }

  Future<IResponse> getRecommendedShoppingList(String listName) async {
    String prompt = '''
    Gere uma lista de compras recomendada em formato JSON.  
    A lista deve ser um array de objetos, cada um com as seguintes propriedades:  
    - `name`: nome do item  
    - `unit`: quantidade (apenas número inteiro ou decimal, representando a quantidade de unidades compradas, por exemplo, 1 pacote, 2 unidades, etc.)  
    - `value`: valor estimado por **unidade normal de compra** (por exemplo, o preço de **1 pacote de arroz de 5kg**, não de 1kg).  

    **Regras importantes:**  
    1. A quantidade (`unit`) deve ser coerente com o tipo de produto e hábitos de consumo (ex: normalmente compra-se 1 ou 2 pacotes de arroz).  
    2. O valor (`value`) deve ser realista, sempre representando o **preço de uma unidade completa do item** (ex: preço de **um pacote de arroz de 5kg** ou **um pacote de papel higiênico com 12 rolos**).  
    3. Evite sugerir quantidades muito grandes ou valores unitários exagerados.  

    Exemplo de formato esperado:
    ```json
    [  {"name": "Arroz (5kg)", "unit": 2, "value": 25.00},  {"name": "Feijão (1kg)", "unit": 1, "value": 7.50},  {"name": "Macarrão (500g)", "unit": 2, "value": 4.30}]

    ''';
    if (shoppingLists.containsKey(listName) &&
        shoppingLists[listName]!.isNotEmpty) {
      prompt +=
          ' baseada na lista anterior: ${shoppingLists[listName]!.map((item) => item.name).join(', ')}';
    }
    final String apiResponse =
        await geminiApiService.getRecommendedShoppingList(prompt);
    try {
      if (apiResponse.startsWith('Erro')) {
        print('Erro ao gerar lista de compras: $apiResponse');
        return IResponse(success: false, message: 'Erro ao gerar lista de compras');
      }
      final dynamic jsonList = jsonDecode(apiResponse);
      if (jsonList == null || jsonList is! List) {
        print("Resposta da API: $apiResponse");
        return IResponse(success: false, message: 'Erro ao gerar lista de compras');
      }
      List<ShoppingItem> recommendedItems = (jsonList)
          .map((itemJson) {
            if (itemJson is! Map<String, dynamic>) {
              print("Resposta da API: $apiResponse");
              return null;
            }
            return ShoppingItem(
              UniqueKey().toString(),
              itemJson['name'] as String,
              itemJson['unit'] as num,
              (itemJson['value'] as num).toDouble(),
              false,
            );
          })
          .whereType<ShoppingItem>()
          .toList();
      if (recommendedItems.isNotEmpty) {
        await addList(listName);
      }
      for (final item in recommendedItems) {
        await addItem(listName, item);
      }
      print("Itens adicionados à lista de compras");
    } catch (e) {
      print("Erro ao decodificar ou adicionar a lista de compras: $e");
      print("Resposta da API: $apiResponse");
    }
    notifyListeners();
    return IResponse(success: true, message: 'Lista de compras gerada com sucesso');
  }
}
