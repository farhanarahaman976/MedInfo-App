class Medicine {
  final String id;
  final String name;
  final String company;
  final String nameBangla;
  final String category;
  final String description;
  final String descriptionBangla;
  final String dosage;
  final String dosageBangla;
  final List<String> uses;
  final List<String> usesBangla;
  final double unitPrice;
  final List<String> sideEffects;
  final List<String> sideEffectsBangla;
  final String usageBangla;
  final int quantity;
  final int? stockQuantity; 
  final String? imageUrl; 
  final double averageRating; 
  final int reviewCount; 

  const Medicine({
    this.id = '',
    required this.name,
    this.company = '',
    required this.nameBangla,
    required this.category,
    required this.description,
    required this.descriptionBangla,
    required this.dosage,
    required this.dosageBangla,
    required this.uses,
    required this.usesBangla,
    double? price,
    double? unitPrice,
    required this.sideEffects,
    required this.sideEffectsBangla,
    required this.usageBangla,
    this.quantity = 1,
    this.stockQuantity,
    this.imageUrl,
    this.averageRating = 0.0, // NOTUN
    this.reviewCount = 0, // NOTUN
  }) : unitPrice = unitPrice ?? price ?? 0.0;

  double get displayPrice => unitPrice;
  double get price => unitPrice;

  // Firebase-এ পাঠানোর জন্য (id document ID হিসেবে আলাদাভাবে ব্যবহৃত হয়, তাই map-এ রাখা হয় না)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'nameBangla': nameBangla,
      'category': category,
      'description': description,
      'descriptionBangla': descriptionBangla,
      'dosage': dosage,
      'dosageBangla': dosageBangla,
      'uses': uses,
      'usesBangla': usesBangla,
      'unitPrice': unitPrice,
      'sideEffects': sideEffects,
      'sideEffectsBangla': sideEffectsBangla,
      'usageBangla': usageBangla,
      'quantity': quantity,
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      'averageRating': averageRating, // NOTUN
      'reviewCount': reviewCount, // NOTUN
    };
  }

  // Firebase থেকে আনার জন্য
  factory Medicine.fromMap(Map<String, dynamic> map, String id) {
    return Medicine(
      id: id,
      name: map['name'] ?? '',
      company: map['company'] ?? '',
      nameBangla: map['nameBangla'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      descriptionBangla: map['descriptionBangla'] ?? '',
      dosage: map['dosage'] ?? '',
      dosageBangla: map['dosageBangla'] ?? '',
      uses: List<String>.from(map['uses'] ?? []),
      usesBangla: List<String>.from(map['usesBangla'] ?? []),
      unitPrice:
          map['unitPrice']?.toDouble() ?? map['price']?.toDouble() ?? 0.0,
      sideEffects: List<String>.from(map['sideEffects'] ?? []),
      sideEffectsBangla: List<String>.from(map['sideEffectsBangla'] ?? []),
      usageBangla: map['usageBangla'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt(),
      imageUrl: map['imageUrl'] as String?,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0, // NOTUN
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0, // NOTUN
    );
  }

  Medicine copyWithQuantity(int newQuantity) {
    return Medicine(
      id: id,
      name: name,
      company: company,
      nameBangla: nameBangla,
      category: category,
      description: description,
      descriptionBangla: descriptionBangla,
      dosage: dosage,
      dosageBangla: dosageBangla,
      uses: uses,
      usesBangla: usesBangla,
      unitPrice: unitPrice,
      sideEffects: sideEffects,
      sideEffectsBangla: sideEffectsBangla,
      usageBangla: usageBangla,
      quantity: newQuantity,
      stockQuantity: stockQuantity,
      imageUrl: imageUrl,
      averageRating: averageRating, // NOTUN
      reviewCount: reviewCount, // NOTUN
    );
  }

  // Admin edit form-এর জন্য
  Medicine copyWithDetails({
    String? name,
    String? company,
    String? nameBangla,
    String? category,
    String? description,
    String? descriptionBangla,
    String? dosage,
    String? dosageBangla,
    List<String>? uses,
    List<String>? usesBangla,
    double? unitPrice,
    List<String>? sideEffects,
    List<String>? sideEffectsBangla,
    String? usageBangla,
    String? imageUrl,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      nameBangla: nameBangla ?? this.nameBangla,
      category: category ?? this.category,
      description: description ?? this.description,
      descriptionBangla: descriptionBangla ?? this.descriptionBangla,
      dosage: dosage ?? this.dosage,
      dosageBangla: dosageBangla ?? this.dosageBangla,
      uses: uses ?? this.uses,
      usesBangla: usesBangla ?? this.usesBangla,
      unitPrice: unitPrice ?? this.unitPrice,
      sideEffects: sideEffects ?? this.sideEffects,
      sideEffectsBangla: sideEffectsBangla ?? this.sideEffectsBangla,
      usageBangla: usageBangla ?? this.usageBangla,
      quantity: quantity,
      stockQuantity: stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      averageRating: averageRating, // NOTUN
      reviewCount: reviewCount, // NOTUN
    );
  }

  // Admin-er stock update form-er jonno
  Medicine copyWithStock(int newStock) {
    return Medicine(
      id: id,
      name: name,
      company: company,
      nameBangla: nameBangla,
      category: category,
      description: description,
      descriptionBangla: descriptionBangla,
      dosage: dosage,
      dosageBangla: dosageBangla,
      uses: uses,
      usesBangla: usesBangla,
      unitPrice: unitPrice,
      sideEffects: sideEffects,
      sideEffectsBangla: sideEffectsBangla,
      usageBangla: usageBangla,
      quantity: quantity,
      stockQuantity: newStock,
      imageUrl: imageUrl,
      averageRating: averageRating, // NOTUN
      reviewCount: reviewCount, // NOTUN
    );
  }
}