class FamilyMember {
  final int? id;
  final int? profileId;
  String name;
  String phone;
  String relation;
  String? ageGroup;
  String role;
  String inviteStatus;
  int? linkedPassengerId;
  bool canTrackRides;
  bool canPayForRides;
  double? monthlySpendingLimit;
  String? inviterName;
  String? ownerName;

  FamilyMember({
    this.id,
    this.profileId,
    required this.name,
    required this.phone,
    required this.relation,
    this.ageGroup,
    this.role = 'member',
    this.inviteStatus = 'contact',
    this.linkedPassengerId,
    this.canTrackRides = true,
    this.canPayForRides = false,
    this.monthlySpendingLimit,
    this.inviterName,
    this.ownerName,
  });

  bool get isLinked => linkedPassengerId != null;
  bool get isPending => inviteStatus == 'pending';
  bool get isAccepted => inviteStatus == 'accepted';
  bool get isParent => role == 'parent';
  bool get isOwner => role == 'owner';

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        id: j['id'] as int?,
        profileId: j['profileId'] as int?,
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        relation: j['relation']?.toString() ?? '',
        ageGroup: j['ageGroup']?.toString(),
        role: j['role']?.toString() ?? 'member',
        inviteStatus: j['inviteStatus']?.toString() ?? 'contact',
        linkedPassengerId: j['linkedPassengerId'] as int?,
        canTrackRides: j['canTrackRides'] == true,
        canPayForRides: j['canPayForRides'] == true,
        monthlySpendingLimit: j['monthlySpendingLimit'] != null
            ? double.tryParse(j['monthlySpendingLimit'].toString())
            : null,
        inviterName: j['inviterName']?.toString(),
        ownerName: j['ownerName']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
        if (ageGroup != null) 'ageGroup': ageGroup,
        'role': role,
        if (linkedPassengerId != null) 'linkedPassengerId': linkedPassengerId,
        'canTrackRides': canTrackRides,
        'canPayForRides': canPayForRides,
        if (monthlySpendingLimit != null)
          'monthlySpendingLimit': monthlySpendingLimit,
      };

  Map<String, dynamic> toInviteJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
        if (ageGroup != null) 'ageGroup': ageGroup,
        'role': role,
        'canTrackRides': canTrackRides,
        'canPayForRides': canPayForRides,
        if (monthlySpendingLimit != null)
          'monthlySpendingLimit': monthlySpendingLimit,
      };
}

class FamilyHub {
  final Map<String, dynamic> profile;
  final List<FamilyMember> members;
  final List<FamilyMember> pendingInvites;
  final List<Map<String, dynamic>> activeRides;
  final bool canManage;
  final bool isOwner;

  FamilyHub({
    required this.profile,
    required this.members,
    required this.pendingInvites,
    required this.activeRides,
    required this.canManage,
    required this.isOwner,
  });

  factory FamilyHub.fromJson(Map<String, dynamic> j) => FamilyHub(
        profile: Map<String, dynamic>.from(j['profile'] as Map? ?? {}),
        members: (j['members'] as List? ?? [])
            .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        pendingInvites: (j['pendingInvites'] as List? ?? [])
            .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        activeRides: (j['activeRides'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        canManage: j['canManage'] == true,
        isOwner: j['isOwner'] == true,
      );
}
