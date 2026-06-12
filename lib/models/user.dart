class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String password;

  const User({
    this.uid = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.password = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
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
    );
  }
}
