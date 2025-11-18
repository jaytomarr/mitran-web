class ContactInfo {
  final String phone;
  final String email;

  const ContactInfo({
    required this.phone,
    required this.email,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}