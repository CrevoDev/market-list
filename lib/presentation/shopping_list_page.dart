import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/my_app_state.dart';
import '../popups/add_item_dialog.dart';
import '../popups/edit_item_dialog.dart';

class ShoppingListPage extends StatelessWidget {
  final String listName;

  ShoppingListPage({required this.listName});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, appState, child) {
        var list = appState.shoppingLists[listName] ?? [];
        var items = list.where((item) => item.isChecked).toList();
        var totalValue = items.fold(0.0, (sum, item) => sum + item.value * item.unit);
        var totalValueSpected = list.fold(0.0, (sum, item) => sum + item.value * item.unit);
        var isAllSelected = items.length == list.length;

        if (list.isNotEmpty) {
          list.sort((a, b) => a.name.compareTo(b.name));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(listName),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total de Itens: ${items.length}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total de Itens Esperado: ${list.length}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Valor Total: \$${totalValue.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Text(
                          'Valor Total Esperado: \$${totalValueSpected.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: list.isNotEmpty
                                ? () async {
                                    isAllSelected = !isAllSelected;
                                    await appState.selectAllItems(
                                        listName, isAllSelected);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAllSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isAllSelected
                                ? 'Desmarcar Todos'
                                : 'Selecionar Todos'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ChangeNotifierProvider.value(
                          value: appState,
                          child: AddItemDialog(listName: listName),
                        );
                      },
                    );
                  },
                  child: Text('Adicionar Item'),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      var item = list[index];
                      return Dismissible(
                        key: Key(item.id),
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
                                return ChangeNotifierProvider.value(
                                  value: appState,
                                  child: EditItemDialog(
                                      listName: listName, item: item),
                                );
                              },
                            );
                            return false;
                          } else if (direction == DismissDirection.endToStart) {
                            await appState.removeItem(listName, item.id);
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
                            title: Text(
                                '${item.name} (${item.unit}) - \$${item.value.toStringAsFixed(2)}'),
                            trailing: Checkbox(
                              value: item.isChecked,
                              onChanged: (bool? value) async {
                                await appState.updateItemChecked(
                                    listName, item.id, value ?? false);
                              },
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return ChangeNotifierProvider.value(
                                    value: appState,
                                    child: EditItemDialog(
                                        listName: listName, item: item),
                                  );
                                },
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
        );
      },
    );
  }
}
