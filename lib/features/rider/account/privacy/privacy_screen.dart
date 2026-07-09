import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/a11y.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/legal_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../legal/legal_document_screen.dart';
import '../../../splash/splash_screen.dart';
import '../../services/rider_service.dart';
import '../my_account_all/service/account_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _exporting = false;
  bool _deleting = false;
  bool _loadingLegal = false;
  bool _accepting = false;
  bool _needsConsent = false;
  bool _loadingDsr = false;
  bool _submittingDsr = false;
  List<LegalDocumentView> _legalDocs = [];
  List<dynamic> _dsrRequests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLegal();
      _loadDsrRequests();
    });
  }

  Future<void> _loadDsrRequests() async {
    setState(() => _loadingDsr = true);
    try {
      final list = await RiderService.instance.getMyPrivacyRequests();
      if (mounted) setState(() => _dsrRequests = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingDsr = false);
  }

  Future<void> _submitDsr(String type) async {
    if (_submittingDsr) return;
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.privacyRequestTitle),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l.privacyOptionalDetails,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.submit),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submittingDsr = true);
    try {
      await RiderService.instance.submitPrivacyDsr(
        type: type,
        details: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.privacyRequestSubmitted),
        ),
      );
      await _loadDsrRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submittingDsr = false);
    }
  }

  Future<void> _loadLegal() async {
    setState(() => _loadingLegal = true);
    try {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final docs = await LegalService.instance.fetchPassengerBundle(isAr: isAr);
      bool needs = false;
      try {
        final status = await LegalService.instance.consentStatus();
        needs = status['needsConsent'] == true;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _legalDocs = docs;
          _needsConsent = needs;
        });
      }
    } catch (_) {
      /* keep export/delete usable */
    } finally {
      if (mounted) setState(() => _loadingLegal = false);
    }
  }

  Future<void> _acceptPolicies() async {
    setState(() => _accepting = true);
    try {
      await LegalService.instance.acceptConsents();
      if (!mounted) return;
      setState(() => _needsConsent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.registerPolicies)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _downloadData() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _exporting = true);
    try {
      final data = await RiderService.instance.exportPersonalData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      if (!mounted) return;
      Navigator.pop(context);
      await Share.share(json, subject: 'NovaRide — ${l.downloadYourData}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dataExportReady)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l.deleteAccount),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    setState(() => _deleting = true);
    final success = await AccountService.instance.deleteAccount();
    if (!mounted) return;
    setState(() => _deleting = false);

    if (success) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.retry)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.privacy,
      child: Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.privacy)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/privacy.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.privacy,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingLegal)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ..._legalDocs.map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _card(
                      icon: doc.slug.contains('terms')
                          ? Icons.description_outlined
                          : Icons.policy_outlined,
                      title: doc.title,
                      subtitle: doc.summary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LegalDocumentScreen(document: doc),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_needsConsent) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _accepting ? null : _acceptPolicies,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16a34a),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _accepting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(l.registerPolicies),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 12),
              Text(
                l.yourPersonalData,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              _card(
                icon: Icons.lock_outline,
                title: l.yourPersonalData,
                subtitle: l.downloadYourData,
                onTap: () => _showDownloadSheet(context),
              ),
              const SizedBox(height: 16),
              Text(
                l.privacyRequestsGdpr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              _card(
                icon: Icons.download_outlined,
                title: l.privacyAccessTitle,
                subtitle: l.privacyAccessSubtitle,
                onTap: _submittingDsr ? null : () => _submitDsr('access'),
              ),
              const SizedBox(height: 10),
              _card(
                icon: Icons.delete_forever_outlined,
                title: l.privacyErasureTitle,
                subtitle: l.privacyErasureSubtitle,
                onTap: _submittingDsr ? null : () => _submitDsr('erasure'),
                color: Colors.orange,
              ),
              if (_loadingDsr)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_dsrRequests.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._dsrRequests.take(5).map((r) {
                  final m = r is Map ? r : <String, dynamic>{};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m['type'] ?? ''} — ${m['status'] ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              _card(
                icon: Icons.delete_outline,
                title: l.deleteAccount,
                subtitle: l.deleteAccountDesc,
                onTap: _deleting ? null : _confirmDelete,
                color: Colors.red,
              ),
            ],
          ),
          if (_deleting)
            const ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color color = const Color(0xff16a34a),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  void _showDownloadSheet(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return FractionallySizedBox(
          heightFactor: 0.45,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.downloadYourData,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.downloadYourDataDesc,
                  style: const TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _exporting
                      ? null
                      : () {
                          Navigator.pop(sheetCtx);
                          _downloadData();
                        },
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff16a34a),
                          const Color(0xff16a34a).withOpacity(.7),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _exporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l.download,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
