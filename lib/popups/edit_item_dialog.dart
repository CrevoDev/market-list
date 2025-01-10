import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../state_management/my_app_state.dart';
import '../maps/shopping_item.dart';

class EditItemDialog extends StatelessWidget {
  final String listName;
  final ShoppingItem item;

  EditItemDialog({required this.listName, required this.item});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var nameController = TextEditingController(text: item.name);
    var unitController = TextEditingController(text: item.unit.toString());
    var valueController =
        TextEditingController(text: item.value.toString().replaceAll('.', ','));

    var allItems = appState.shoppingLists.values.expand((list) => list).toList();
    var itemNames = allItems.map((item) => item.name).toSet().toList();

    return AlertDialog(
      title: Text('Editar Item'),
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
          TextField(
            controller: valueController,
            decoration: InputDecoration(labelText: 'Valor'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                String newText =
                    newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

                // Garante que o texto tenha pelo menos três dígitos para a formatação
                while (newText.length < 3) {
                  newText = '0$newText';
                }

                // Remove zeros à esquerda, exceto se o valor for menor que 1 real (ex: 0,01)
                newText = newText.replaceFirst(RegExp(r'^0+(?=\d{3,})'), '');

                // Formata o texto com a vírgula na posição correta
                String formattedText =
                    '${newText.substring(0, newText.length - 2)},${newText.substring(newText.length - 2)}';

                // Calcula a nova posição do cursor
                int newCursorPosition = formattedText.length -
                    (newValue.text.length - newValue.selection.baseOffset);

                // Retorna o texto formatado e reposiciona o cursor corretamente
                return TextEditingValue(
                  text: formattedText,
                  selection: TextSelection.collapsed(offset: newCursorPosition),
                );
              })
            ],
          )
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
            var itemValue =
                double.tryParse(valueController.text.replaceAll(',', '.')) ??
                    0.0;
            if (itemName.isNotEmpty && !itemUnit.isNaN) {
              var newItem = ShoppingItem(
                  item.id, itemName, itemUnit, itemValue, item.isChecked);
              await appState.updateItem(listName, newItem);
              Navigator.of(context).pop();
            }
          },
          child: Text('Salvar'),
        ),
      ],
    );
  }
}
