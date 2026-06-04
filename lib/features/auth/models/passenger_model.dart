import '../../../core/utils/media_url.dart';

class PassengerModel {
  final int id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? gender;
  final String? birthDate;
  final String? homeAddress;
  final String? workAddress;
  final String? profileImage;
  final bool profileCompleted;

  const PassengerModel({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.birthDate,
    this.homeAddress,
    this.workAddress,
    this.profileImage,
    required this.profileCompleted,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s?.isNotEmpty == true).join(' ');

  String? get profileImageUrl => resolveMediaUrl(profileImage);

  bool get isProfileComplete => profileCompleted;

  PassengerModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    String? birthDate,
    String? homeAddress,
    String? workAddress,
    String? profileImage,
    bool? profileCompleted,
  }) =>
      PassengerModel(
        id: id,
        phone: phone,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        homeAddress: homeAddress ?? this.homeAddress,
        workAddress: workAddress ?? this.workAddress,
        profileImage: profileImage ?? this.profileImage,
        profileCompleted: profileCompleted ?? this.profileCompleted,
      );

  factory PassengerModel.fromJson(Map<String, dynamic> j) => PassengerModel(
        id: j['id'] ?? 0,
        phone: j['phone'] ?? '',
        firstName: j['firstName'],
        lastName: j['lastName'],
        email: j['email'],
        gender: j['gender'],
        birthDate: j['birthDate'],
        homeAddress: j['homeAddress'],
        workAddress: j['workAddress'],
        profileImage: resolveMediaUrl(j['profileImage']?.toString()),
        profileCompleted: j['profileCompleted'] ?? false,
      );
}
