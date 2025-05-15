class Medicine {
  final String id;
  final String name;
  final String manufacturer;
  final String category;
  final String description;
  final double mrp;
  final double purchasePrice;
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.description,
    required this.mrp,
    required this.purchasePrice,
    required this.createdAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      mrp: (json['mrp'] ?? 0).toDouble(),
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Distributor {
  final String id;
  final String name;
  final String contactNumber;
  final String email;
  final String address;
  final DateTime createdAt;

  Distributor({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.address,
    required this.createdAt,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) {
    return Distributor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class InventoryItem {
  final String id;
  final Medicine medicine;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;
  final Distributor distributor;
  final DateTime addedOn;

  InventoryItem({
    required this.id,
    required this.medicine,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.distributor,
    required this.addedOn,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      medicine: Medicine.fromJson(json['medicine'] ?? {}),
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now(),
      quantity: json['quantity'] ?? 0,
      distributor: Distributor.fromJson(json['distributor'] ?? {}),
      addedOn: json['addedOn'] != null
          ? DateTime.parse(json['addedOn'])
          : DateTime.now(),
    );
  }
}

// Models for API requests
class AddInventoryRequest {
  final String medicineId;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;
  final String distributorId;

  AddInventoryRequest({
    required this.medicineId,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.distributorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicineId': medicineId,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate.toIso8601String().split('T')[0],
      'quantity': quantity,
      'distributorId': distributorId,
    };
  }
}

class UpdateInventoryRequest {
  final int quantity;
  final DateTime expiryDate;

  UpdateInventoryRequest({
    required this.quantity,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String().split('T')[0],
    };
  }
}
