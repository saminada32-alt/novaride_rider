/// Normalizes Syrian/international numbers for [tel:] URIs.
String? normalizePhoneForTel(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('+')) return digits;
  if (digits.startsWith('00')) return '+${digits.substring(2)}';
  if (digits.startsWith('963')) return '+$digits';
  if (digits.startsWith('0')) return '+963${digits.substring(1)}';
  return '+$digits';
}
