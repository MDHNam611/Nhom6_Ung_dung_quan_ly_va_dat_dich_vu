class AddressModel {
  final String id;
  final String cityDistrictWard; 
  final String streetBuilding; 
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.cityDistrictWard,
    required this.streetBuilding,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AddressModel(
      id: id,
      cityDistrictWard: map['cityDistrictWard'] ?? '',
      streetBuilding: map['streetBuilding'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cityDistrictWard': cityDistrictWard,
      'streetBuilding': streetBuilding,
      'isDefault': isDefault,
    };
  }
}