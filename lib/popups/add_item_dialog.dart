import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state_management/my_app_state.dart';
import '../maps/shopping_item.dart';

class AddItemDialog extends StatelessWidget {
  final String listName;

  AddItemDialog({required this.listName});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var nameController = TextEditingController();
    var unitController = TextEditingController();
    var valueController = TextEditingController();

    var allItems = appState.shoppingLists.values.expand((list) => list).toList();
    var itemNames = allItems.map((item) => item.name).toSet().toList();

    return AlertDialog(
      title: Text('Adicionar Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return itemNames.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              nameController.text = selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              return TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(labelText: 'Nome do Item'),
              );
            },
          ),
          TextField(
            controller: unitController,
            decoration: InputDecoration(labelText: 'Unidade'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[1-9][0-9]*')),
            ],
          ),
        ],
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
            var itemName = nameController.text;
            var itemUnit = num.parse(unitController.text);
            var itemValue = double.tryParse(valueController.text) ?? 0.0;
            var existingItem = allItems.firstWhere((item) => item.name == itemName, orElse: () => ShoppingItem('', '', 0, 0.0, false));
            itemValue = existingItem.value;
            if (itemName.isNotEmpty && !itemUnit.isNaN) {
              var id = UniqueKey().toString();
              var item = ShoppingItem(id, itemName, itemUnit, itemValue, false);
              await appState.addItem(listName, item);
              Navigator.of(context).pop();
            }
          },
          child: Text('Adicionar'),
        ),
      ],
    );
  }
}
