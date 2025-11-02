class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String imageUrl;
  final int estimatedDuration; 

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    required this.estimatedDuration, 
  });

  factory ServiceModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      estimatedDuration: map['estimatedDuration'] ?? 0, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'estimatedDuration': estimatedDuration, 
    };
  }
}