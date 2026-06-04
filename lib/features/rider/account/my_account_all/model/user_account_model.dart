class UserAccountModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  UserAccountModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory UserAccountModel.fromJson(Map<String, dynamic> json) {
    return UserAccountModel(
      id: json["_id"],
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      email: json["email"],
    );
  }
}
