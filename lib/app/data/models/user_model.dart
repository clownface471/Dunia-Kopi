class UserModel {
  final String uid;
  final String email;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    this.role = 'customer',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
    };
  }
}
