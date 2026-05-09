class UserModel {
  final String userId;
  final String fullName;
  final String username;
  final String role;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'role': role,
    };
  }

  @override
  String toString() => fullName;
}
