import '../../l10n/app_localizations.dart';

/// Internal keys set by [AuthProvider] — mapped to l10n in the UI.
const authErrNetwork = '@@auth:network@@';
const authErrServerTimeout = '@@auth:server_timeout@@';
const authErrNoConnection = '@@auth:no_connection@@';
const authErrInvalidOtp = '@@auth:invalid_otp@@';
const authErrSendOtp = '@@auth:send_otp@@';
const authErrAccountNotFound = '@@auth:account_not_found@@';
const authErrInvalidResponse = '@@auth:invalid_response@@';
const authErrUpdateProfile = '@@auth:update_profile@@';
const authErrUploadPhoto = '@@auth:upload_photo@@';

String localizeAuthError(String? raw, AppLocalizations t) {
  if (raw == null || raw.isEmpty) return t.actionFailed;
  switch (raw) {
    case authErrNetwork:
      return t.networkSlowRetry;
    case authErrServerTimeout:
      return 'الخادم تأخر في الرد — حاول مجدداً';
    case authErrNoConnection:
      return 'تعذّر الاتصال بالخادم — تحقق من الإنترنت';
    case authErrInvalidOtp:
      return t.invalidOtp;
    case authErrSendOtp:
      return t.failedToSendOtp;
    case authErrAccountNotFound:
      return t.accountNotRegistered;
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
  final lower = msg.toLowerCase();
  if (msg.startsWith('NET[')) return t.networkSlowRetry;
  if (lower.contains('invalid') && lower.contains('otp')) {
    return 'رمز غير صحيح — استخدم آخر SMS';
  }
  if (lower.contains('otp')) {
    return t.invalidOtp;
  }
  if (lower.contains('timeout') || msg.contains('مهلة') || msg.contains('تأخر')) {
    return 'الخادم تأخر في الرد — حاول مجدداً';
  }
  if (lower.contains('socket') || msg.contains('الاتصال بالخادم')) {
    return 'تعذّر الاتصال بالخادم — تحقق من الإنترنت';
  }
  if (lower.contains('sms') || msg.contains('SMS_DELIVERY')) {
    return t.failedToSendOtp;
  }
  if (lower.contains('account not registered')) {
    return t.accountNotRegistered;
  }
  if (lower.contains('legal consent')) {
    return t.legalText;
  }
  return msg.isEmpty ? t.actionFailed : msg;
}
