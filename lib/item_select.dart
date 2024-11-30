class ItemSelect {
  final String name;
  final String id;

  ItemSelect({required this.name, required this.id});

  factory ItemSelect.fromJson(Map<String, dynamic> json) {
    return ItemSelect(
      name: json['ten'],
      id: json['id'],
    );
  }
}
