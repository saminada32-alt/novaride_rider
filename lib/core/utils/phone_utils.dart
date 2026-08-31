/// Normalize phone for auth API (E.164-style, dedupes country code).
String buildAuthPhone(String dialCode, String localInput) {
  final code = dialCode.replaceAll(RegExp(r'\D'), '');
  var local = localInput.replaceAll(RegExp(r'\D'), '');
  if (local.startsWith(code)) return '+$local';
  if (local.startsWith('0')) local = local.substring(1);
  return '+$code$local';
}

/// Normalize Syrian mobile for `tel:` links (+9639XXXXXXXX), or null if invalid.
String? normalizePhoneForTel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('963963')) {
    digits = '963${digits.substring(6)}';
  } else if (digits.startsWith('0') && !digits.startsWith('963')) {
    digits = digits.substring(1);
  }
  if (digits.length == 9 && digits.startsWith('9')) digits = '963$digits';
  if (!RegExp(r'^9639\d{8}$').hasMatch(digits)) return null;
  return '+$digits';
}
