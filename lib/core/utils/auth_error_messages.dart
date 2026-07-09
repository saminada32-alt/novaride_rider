import '../../l10n/app_localizations.dart';

/// Internal keys set by [AuthProvider] — mapped to l10n in the UI.
const authErrNetwork = '@@auth:network@@';
const authErrInvalidOtp = '@@auth:invalid_otp@@';
const authErrSendOtp = '@@auth:send_otp@@';
const authErrInvalidResponse = '@@auth:invalid_response@@';
const authErrUpdateProfile = '@@auth:update_profile@@';
const authErrUploadPhoto = '@@auth:upload_photo@@';

String localizeAuthError(String? raw, AppLocalizations t) {
  if (raw == null || raw.isEmpty) return t.actionFailed;
  switch (raw) {
    case authErrNetwork:
      return t.noInternetConnection;
    case authErrInvalidOtp:
      return t.invalidOtp;
    case authErrSendOtp:
      return t.failedToSendOtp;
    case authErrInvalidResponse:
      return t.invalidResponse;
    case authErrUpdateProfile:
      return t.failedToUpdateProfile;
    case authErrUploadPhoto:
      return t.failedToUploadPhoto;
    default:
      break;
  }
  final msg = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (msg.startsWith('NET[')) return t.noInternetConnection;
  if (msg.toLowerCase().contains('invalid otp') ||
      msg.toLowerCase().contains('otp')) {
    return t.invalidOtp;
  }
  return msg.isEmpty ? t.actionFailed : msg;
}
