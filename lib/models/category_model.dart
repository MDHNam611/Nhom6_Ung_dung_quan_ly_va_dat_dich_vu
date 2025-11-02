class CategoryModel {
  final String id;
  final String name;
  final String description; 

  CategoryModel({
    required this.id, 
    required this.name,
    required this.description, 
  });

  factory CategoryModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '', 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description, 
    };
  }
}