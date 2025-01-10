import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class GeminiApiService {
  static late String _apiKey;
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent";

  static Future<void> initializeWithCredentials() async {
    final credentials = await rootBundle.loadString('assets/credentials.json');
    final json = jsonDecode(credentials);
    if (json['gemini_api_key'] == null) {
      throw Exception('gemini_api_key not found in credentials');
    }
    _apiKey = json['gemini_api_key'];
  }

  Future<String> getRecommendedShoppingList(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': _apiKey,
    };

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response =
          await http.post(Uri.parse(_apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        // Tenta decodificar a resposta JSON
        final dynamic jsonResponse = jsonDecode(response.body);

        // Verifica se jsonResponse é null
        if (jsonResponse == null) {
          print(
              "O jsonDecode retornou null, portanto a resposta da api não continha dados ou estava num formato inválido");
          return 'Erro ao gerar a lista de compras';
        }

        // Verifica se jsonResponse é um Map
        if (jsonResponse is! Map<String, dynamic>) {
          print(
              "O jsonResponse não é do tipo Map<String, dynamic> como esperado");
          return 'Erro ao gerar a lista de compras';
        }

        // Obtém o texto da resposta
        final dynamic candidates = jsonResponse['candidates'];

        //Verifica se candidates existe
        if (candidates == null || candidates is! List) {
          print(
              "O campo candidates não existe ou não é uma lista como esperado");
          return 'Erro ao gerar a lista de compras';
        }
        // Obtém o primeiro candidato da lista (considerando que existe)
        final dynamic firstCandidate =
            candidates.isNotEmpty ? candidates[0] : null;

        //Verifica se firstCandidate existe
        if (firstCandidate == null ||
            firstCandidate is! Map<String, dynamic>) {
          print(
              "O primeiro candidato não existe ou não é um Map<String, dynamic> como esperado");
          return 'Erro ao gerar a lista de compras';
        }

        final dynamic content = firstCandidate['content'];

        if (content == null || content is! Map<String, dynamic>) {
          print(
              "O campo content não existe ou não é um Map<String, dynamic> como esperado");
          return 'Erro ao gerar a lista de compras';
        }

        final dynamic parts = content['parts'];

        if (parts == null || parts is! List) {
          print("O campo parts não existe ou não é uma List como esperado");
          return 'Erro ao gerar a lista de compras';
        }

        // Obtém o primeiro part (considerando que existe)
        final dynamic firstPart = parts.isNotEmpty ? parts[0] : null;

        if (firstPart == null || firstPart is! Map<String, dynamic>) {
          print(
              "O primeiro part não existe ou não é um Map<String, dynamic> como esperado");
          return 'Erro ao gerar a lista de compras';
        }
        final String? jsonText = firstPart['text'];

        // Verifica se o texto é nulo ou vazio
        if (jsonText == null || jsonText.isEmpty) {
          print("O texto da resposta não foi encontrado ou está vazio");
          return "Erro ao gerar a lista de compras";
        }
        // Remove os delimitadores "```json" e "```"
        final String cleanedJsonText =
            jsonText.replaceAll('```json', '').replaceAll('```', '').trim();
        return cleanedJsonText;
      } else {
        print(
            'Request failed with status: ${response.statusCode} and body: ${response.body}');
        return 'Erro ao gerar a lista de compras';
      }
    } catch (e) {
      print('Error during API call: $e');
      return 'Erro ao gerar a lista de compras';
    }
  }
}
