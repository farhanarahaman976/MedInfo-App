class Medicine {
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

  const Medicine({
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
  }) : unitPrice = unitPrice ?? price ?? 0.0;

  double get displayPrice => unitPrice;
  double get price => unitPrice;

  // Firebase-এ পাঠানোর জন্য
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
    };
  }

  // Firebase থেকে আনার জন্য
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
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
    );
  }
}
