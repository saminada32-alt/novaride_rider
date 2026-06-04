import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the promo code selected by the passenger for the next ride.
class PromoProvider extends ChangeNotifier {
  static const _storageKey = 'selected_promo_code';
  static const _descKey = 'selected_promo_desc';
  static const _pctKey = 'selected_promo_pct';

  String? _code;
  String? _description;
  double? _discountPercent;

  String? get code => _code;
  String? get description => _description;
  double? get discountPercent => _discountPercent;
  bool get hasPromo => _code != null && _code!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_storageKey);
    _description = prefs.getString(_descKey);
    _discountPercent = prefs.getDouble(_pctKey);
    notifyListeners();
  }

  Future<void> setPromo({
    required String code,
    required String description,
    required double discountPercent,
  }) async {
    _code = code.trim().toUpperCase();
    _description = description;
    _discountPercent = discountPercent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _code!);
    await prefs.setString(_descKey, description);
    await prefs.setDouble(_pctKey, discountPercent);
    notifyListeners();
  }

  Future<void> clear() async {
    _code = null;
    _description = null;
    _discountPercent = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_descKey);
    await prefs.remove(_pctKey);
    notifyListeners();
  }
}
