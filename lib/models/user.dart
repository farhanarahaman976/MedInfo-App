class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String password;

  // ── New medical fields ──
  final String bloodGroup;
  final double? weight;
  final double? height;
  final bool hasDiabetes;
  final bool hasHypertension;
  final bool hasThyroid;
  final bool hasHeartDisease;
  final bool hasAsthma;
  final String emergencyContactName;
  final String emergencyContactPhone;

  const User({
    this.uid = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.password = '',
    this.bloodGroup = '',
    this.weight,
    this.height,
    this.hasDiabetes = false,
    this.hasHypertension = false,
    this.hasThyroid = false,
    this.hasHeartDisease = false,
    this.hasAsthma = false,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'bloodGroup': bloodGroup,
      'weight': weight,
      'height': height,
      'hasDiabetes': hasDiabetes,
      'hasHypertension': hasHypertension,
      'hasThyroid': hasThyroid,
      'hasHeartDisease': hasHeartDisease,
      'hasAsthma': hasAsthma,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      password: json['password'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      hasDiabetes: json['hasDiabetes'] as bool? ?? false,
      hasHypertension: json['hasHypertension'] as bool? ?? false,
      hasThyroid: json['hasThyroid'] as bool? ?? false,
      hasHeartDisease: json['hasHeartDisease'] as bool? ?? false,
      hasAsthma: json['hasAsthma'] as bool? ?? false,
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
    );
  }

  User copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? password,
    String? bloodGroup,
    double? weight,
    double? height,
    bool? hasDiabetes,
    bool? hasHypertension,
    bool? hasThyroid,
    bool? hasHeartDisease,
    bool? hasAsthma,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      password: password ?? this.password,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasThyroid: hasThyroid ?? this.hasThyroid,
      hasHeartDisease: hasHeartDisease ?? this.hasHeartDisease,
      hasAsthma: hasAsthma ?? this.hasAsthma,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}