import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/my_app_state.dart';
import 'shopping_list_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var textController = TextEditingController();
    initializeDateFormatting('pt_BR', null);
    var currentMonthYear = toBeginningOfSentenceCase(DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Listas de Compras'),
      ),
      body: Padding(
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
                        var listName = textController.text.isEmpty ? currentMonthYear : textController.text;
                        if (listName.isNotEmpty) {
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
            Expanded(
              child: ListView.builder(
                itemCount: appState.shoppingLists.keys.length,
                itemBuilder: (context, index) {
                  var listName = appState.shoppingLists.keys.elementAt(index);
                  var items = appState.shoppingLists[listName] ?? [];
                  var selectedItems = items.where((item) => item.isChecked).toList();
                  var totalValue = selectedItems.fold(0.0, (sum, item) => sum + item.value);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(listName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Valor Total: \$${totalValue.toStringAsFixed(2)}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoppingListPage(listName: listName),
                          ),
                        );
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return EditListNameDialog(oldName: listName);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
            Navigator.of(context).pop();
          },
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
