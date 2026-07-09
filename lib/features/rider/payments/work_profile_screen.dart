import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../account/my_account_all/service/account_service.dart';

class WorkProfileScreen extends StatefulWidget {
  const WorkProfileScreen({super.key});

  @override
  State<WorkProfileScreen> createState() => _WorkProfileScreenState();
}

class _WorkProfileScreenState extends State<WorkProfileScreen> {
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final work = context.read<AuthProvider>().passenger?.workAddress ?? '';
    _addressCtrl = TextEditingController(text: work);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final addr = _addressCtrl.text.trim();
    setState(() => _saving = true);

    final data = await AccountService.instance.updateProfile({
      'workAddress': addr.isEmpty ? null : addr,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (data != null) {
      await context.read<AuthProvider>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.savedSuccessfully)));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.retry)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.workProfile,
      child: Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.workProfile)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.workProfileDesc, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          A11yTextField(
            label: l.workAddress,
            child: TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: l.workAddress,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(height: 24),
          A11yButton(
            label: l.save,
            enabled: !_saving,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xff16a34a),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l.save),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
