class ShoppingItem {
  String id;
  String name;
  num unit;
  double value;
  bool isChecked;

  ShoppingItem(this.id, this.name, this.unit, this.value, this.isChecked);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'value': value,
        'isChecked': isChecked,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      json['id'],
      json['name'],
      json['unit'],
      json['value'],
      json['isChecked'],
    );
  }
}
