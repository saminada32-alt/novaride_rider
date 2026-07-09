import '../../l10n/app_localizations.dart';

String localizeApiError(String raw, AppLocalizations t) {
  final msg = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (msg.isEmpty) return t.actionFailed;
  return msg;
}
