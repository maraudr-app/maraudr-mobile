class Association {
  final String id;
  final String name;

  Association({required this.id, required this.name});

  factory Association.fromJson(Map<String, dynamic> json) {
    return Association(
      id: json['id'],
      name: json['name'],
    );
  }
}
