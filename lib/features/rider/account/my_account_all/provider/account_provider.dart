import 'package:flutter/material.dart';
import '../../familyprofile/family_service.dart';
import '../service/account_service.dart';

class AccountProvider extends ChangeNotifier {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? emergencyContact;
  List<dynamic> familyMembers = [];
  bool loading = false;
  String? error;

  // ─── Profile ──────────────────────────────────────────────
  Future<void> loadProfile() async {
    _begin();
    profile = await AccountService.instance.getProfile();
    _done();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _begin();
    final result = await AccountService.instance.updateProfile(data);
    if (result != null) {
      profile = result;
      _done();
      return true;
    }
    _fail('Failed to update');
    return false;
  }

  Future<bool> deleteAccount() async {
    return AccountService.instance.deleteAccount();
  }

  // ─── Emergency Contact ────────────────────────────────────
  Future<void> loadEmergencyContact() async {
    emergencyContact = await AccountService.instance.getEmergencyContact();
    notifyListeners();
  }

  Future<bool> saveEmergencyContact(
    String name,
    String phone,
    String? relation, {
    bool shareLiveLocation = false,
  }) async {
    final ok = await AccountService.instance.saveEmergencyContact(
      name,
      phone,
      relation,
      shareLiveLocation: shareLiveLocation,
    );
    if (ok) {
      emergencyContact = {
        'name': name,
        'phone': phone,
        'shareLiveLocation': shareLiveLocation,
      };
      notifyListeners();
    }
    return ok;
  }

  // ─── Family ───────────────────────────────────────────────
  Future<void> loadFamilyMembers() async {
    try {
      final hub = await FamilyApiService.instance.getHub();
      familyMembers = hub.members.map((m) => m.toJson()).toList();
    } catch (_) {
      familyMembers = await AccountService.instance.getFamilyMembers();
    }
    notifyListeners();
  }

  Future<bool> saveFamilyMembers(List<Map<String, dynamic>> members) async {
    try {
      await FamilyApiService.instance.saveLegacy(members);
      await loadFamilyMembers();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _begin() {
    loading = true;
    error = null;
    notifyListeners();
  }

  void _done() {
    loading = false;
    notifyListeners();
  }

  void _fail(String e) {
    error = e;
    loading = false;
    notifyListeners();
  }
}
