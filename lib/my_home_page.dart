import 'package:flutter/material.dart';
import 'package:namer_app/interfaces/i_response.dart';
import 'package:provider/provider.dart';
import 'state_management/my_app_state.dart';
import 'presentation/shopping_list_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui';
import 'config/app_config.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  bool _showSuccessIcon = false;
  String _newListName = '';

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var textController = TextEditingController();
    initializeDateFormatting('pt_BR', null);
    var currentMonthYear = toBeginningOfSentenceCase(
        DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Listas de Compras'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await appState.refreshCache();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        labelText: 'Adicionar Lista',
                        hintText: currentMonthYear,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () async {
                            var listName = textController.text.isEmpty
                                ? currentMonthYear
                                : textController.text;
                            if (appState.shoppingLists.containsKey(listName)) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Row(
                                      children: [
                                        Icon(Icons.error, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Erro'),
                                      ],
                                    ),
                                    content: Text('Uma lista com o mesmo nome já existe.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              await appState.addList(listName);
                              textController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    var baseListName = 'IA - ${textController.text.isEmpty ? currentMonthYear : textController.text}';
                    var listName = baseListName;
                    int counter = 1;
                    while (appState.shoppingLists.containsKey(listName)) {
                      listName = '$baseListName ($counter)';
                      counter++;
                    }
                    IResponse response = IResponse(success: true, message: listName);
                    if (listName.isNotEmpty) {
                      response = await appState.getRecommendedShoppingList(listName);
                    }
                    setState(() {
                      _isLoading = false;
                      _showSuccessIcon = response.success;
                      _newListName = listName;
                    });
                    if (_showSuccessIcon) {
                      Future.delayed(Duration(seconds: 2), () {
                        setState(() {
                          _showSuccessIcon = false;
                          _newListName = '';
                        });
                      });
                    }
                  },
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 8),
                            Text('Obter Lista Recomendada'),
                          ],
                        ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: appState.shoppingLists.keys.length,
                    itemBuilder: (context, index) {
                      var listName =
                          appState.shoppingLists.keys.elementAt(index);
                      var displayName = listName.startsWith('IA -')
                          ? listName.substring(5)
                          : listName;
                      var items =
                          appState.shoppingLists[listName] ?? [];
                      var selectedItems = items
                          .where((item) => item.isChecked)
                          .toList();
                      var totalValue = selectedItems.fold(
                          0.0, (sum, item) => sum + item.value);

                      return Dismissible(
                        key: Key(listName),
                        background: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 20),
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return EditListNameDialog(oldName: listName);
                              },
                            );
                            return false;
                          } else if (direction == DismissDirection.endToStart) {
                            await appState.removeList(listName);
                            return true;
                          }
                          return false;
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                if (listName.startsWith('IA -'))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: Colors.blue,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                                Text(displayName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (_showSuccessIcon &&
                                    listName == _newListName)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                                'Valor Total: \$${totalValue.toStringAsFixed(2)}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShoppingListPage(
                                      listName: listName),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class EditListNameDialog extends StatelessWidget {
  final String oldName;

  EditListNameDialog({required this.oldName});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var textController = TextEditingController(text: oldName);

    return AlertDialog(
      title: Text('Editar Nome da Lista'),
      content: TextField(
        controller: textController,
        decoration: InputDecoration(labelText: 'Novo Nome'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            appState.removeList(oldName);
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.tertiary),
          child: Text('Deletar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            var newName = textController.text;
            if (newName.isNotEmpty && newName != oldName) {
              await appState.updateListName(oldName, newName);
              Navigator.of(context).pop();
            }
          },
          child: Text('Salvar'),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _spreadsheetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSpreadsheetId();
  }

  Future<void> _loadSpreadsheetId() async {
    String? spreadsheetId = await AppConfig.getSpreadsheetId();
    if (spreadsheetId != null) {
      _spreadsheetController.text = spreadsheetId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _spreadsheetController,
              decoration: InputDecoration(
                labelText: 'ID da Planilha',
                hintText: 'Digite o ID da planilha',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AppConfig.setSpreadsheetId(_spreadsheetController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ID da planilha salvo com sucesso!')),
                );
              },
              child: Text('Salvar'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AppConfig.clearSpreadsheetId();
                _spreadsheetController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ID da planilha removido!')),
                );
              },
              child: Text('Limpar ID da Planilha'),
            ),
            SizedBox(height: 16),
            Text('ID da Planilha Fixa: ${AppConfig.fixedSpreadsheetId}'),
          ],
        ),
      ),
    );
  }
}
