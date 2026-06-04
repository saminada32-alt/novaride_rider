import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../my_account_all/provider/account_provider.dart';
import 'family_service.dart';
import 'model/family_member.dart';

const int _kMaxFamilyMembers = 9;

class FamilyProfileScreen extends StatefulWidget {
  const FamilyProfileScreen({super.key});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen> {
  FamilyHub? _hub;
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _relation;
  String _inviteRole = 'parent';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final hub = await FamilyApiService.instance.getHub();
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _loading = false;
      });
      context.read<AccountProvider>().familyMembers =
          hub.members.map((m) => m.toJson()).toList();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.toString(), error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _relationLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'mother':
        return l.mother;
      case 'father':
        return l.father;
      case 'son':
        return l.son;
      case 'daughter':
        return l.daughter;
      case 'brother':
        return l.brother;
      case 'sister':
        return l.sister;
      case 'wife':
        return l.wife;
      case 'husband':
        return l.husband;
      default:
        return key;
    }
  }

  String _statusLabel(AppLocalizations l, FamilyMember m) {
    switch (m.inviteStatus) {
      case 'pending':
        return l.familyStatusPending;
      case 'accepted':
        return l.familyStatusLinked;
      case 'declined':
        return l.familyStatusDeclined;
      default:
        return l.familyStatusContact;
    }
  }

  Future<void> _acceptInvite(FamilyMember inv) async {
    setState(() => _saving = true);
    try {
      await FamilyApiService.instance.acceptInvite(inv.id!);
      await _load();
      if (mounted) _snack(AppLocalizations.of(context)!.familyInviteAccepted);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _declineInvite(FamilyMember inv) async {
    await FamilyApiService.instance.declineInvite(inv.id!);
    await _load();
  }

  Future<void> _removeMember(FamilyMember m) async {
    if (m.id == null || m.isOwner) return;
    await FamilyApiService.instance.removeMember(m.id!);
    await _load();
  }

  void _openInviteSheet({String role = 'parent', String? relation}) {
    final l = AppLocalizations.of(context)!;
    _inviteRole = role;
    _relation = relation;
    _nameCtrl.clear();
    _phoneCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role == 'parent' ? l.familyInviteParent : l.addFamilyMembers,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l.familyInviteParentDesc,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l.memberName,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.memberPhone,
                hintText: '+9639XXXXXXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _relation,
              decoration: InputDecoration(
                labelText: l.relation,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                if (role == 'parent') ...[
                  DropdownMenuItem(value: 'wife', child: Text(l.wife)),
                  DropdownMenuItem(value: 'husband', child: Text(l.husband)),
                  DropdownMenuItem(value: 'mother', child: Text(l.mother)),
                  DropdownMenuItem(value: 'father', child: Text(l.father)),
                ] else ...[
                  DropdownMenuItem(value: 'son', child: Text(l.son)),
                  DropdownMenuItem(value: 'daughter', child: Text(l.daughter)),
                  DropdownMenuItem(value: 'brother', child: Text(l.brother)),
                  DropdownMenuItem(value: 'sister', child: Text(l.sister)),
                ],
              ],
              onChanged: (v) => _relation = v,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  if (_nameCtrl.text.trim().isEmpty ||
                      _phoneCtrl.text.trim().isEmpty ||
                      _relation == null) {
                    _snack(l.familyFillAll, error: true);
                    return;
                  }
                  setState(() => _saving = true);
                  try {
                    final member = FamilyMember(
                      name: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      relation: _relation!,
                      role: _inviteRole,
                      ageGroup: _inviteRole == 'teen' ? 'teen' : 'adult',
                      canTrackRides: true,
                      canPayForRides: _inviteRole == 'parent' || _inviteRole == 'teen',
                    );
                    await FamilyApiService.instance.invite(member);
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load();
                    if (mounted) _snack(l.familyInviteSent);
                  } catch (e) {
                    _snack(e.toString(), error: true);
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff16a34a),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l.familySendInvite,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: Text(l.familyProfile),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_hub!.pendingInvites.isNotEmpty) ...[
                    _sectionTitle(l.familyPendingInvites),
                    ..._hub!.pendingInvites.map(
                      (inv) => _inviteCard(l, inv),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _heroCard(l),
                  const SizedBox(height: 16),
                  if (_hub!.canManage) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _quickInviteBtn(
                            l.familyInviteMother,
                            Icons.female,
                            () => _openInviteSheet(
                              role: 'parent',
                              relation: 'mother',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quickInviteBtn(
                            l.familyInviteFather,
                            Icons.male,
                            () => _openInviteSheet(
                              role: 'parent',
                              relation: 'father',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_hub!.activeRides.isNotEmpty) ...[
                    _sectionTitle(l.familyActiveRides),
                    ..._hub!.activeRides.map(_rideCard),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle(l.familyMembers),
                  if (_hub!.members.where((m) => !m.isOwner).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l.familyEmptyMembers,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  else
                    ..._hub!.members.where((m) => !m.isOwner).map(
                          (m) => _memberTile(l, m),
                        ),
                ],
              ),
            ),
      floatingActionButton: _hub != null &&
              _hub!.canManage &&
              _hub!.members.length < _kMaxFamilyMembers
          ? FloatingActionButton.extended(
              onPressed: () => _openInviteSheet(role: 'member'),
              backgroundColor: const Color(0xff16a34a),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l.addMember),
            )
          : null,
    );
  }

  Widget _heroCard(AppLocalizations l) {
    final owner = _hub!.profile['ownerName']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff16a34a), Color(0xff15803d)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.familyProfileTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hub!.isOwner ? l.familyYouAreOwner : '${l.familyManagedBy} $owner',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill('${_hub!.members.length}/$_kMaxFamilyMembers ${l.familyMembers}'),
              if (_hub!.canManage) ...[
                const SizedBox(width: 8),
                _pill(l.familyCanManage),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );

  Widget _quickInviteBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xff16a34a)),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xff16a34a)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _inviteCard(AppLocalizations l, FamilyMember inv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.familyInviteFrom} ${inv.inviterName ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${l.relation}: ${_relationLabel(l, inv.relation)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _declineInvite(inv),
                    child: Text(l.decline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _acceptInvite(inv),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff16a34a),
                    ),
                    child: Text(l.accept, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(AppLocalizations l, FamilyMember m) {
    return Dismissible(
      key: ValueKey(m.id ?? m.phone),
      direction: _hub!.canManage && !m.isOwner
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => _removeMember(m),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xff16a34a).withValues(alpha: 0.12),
              child: Text(
                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xff16a34a),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${_relationLabel(l, m.relation)} · ${m.isParent ? l.familyRoleParent : (m.role == 'teen' ? l.teen : l.familyRoleMember)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(m.phone, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusChip(_statusLabel(l, m), m.inviteStatus),
                if (m.canPayForRides)
                  Text(
                    l.familyCanPay,
                    style: const TextStyle(fontSize: 10, color: Color(0xff16a34a)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, String status) {
    Color c = Colors.grey;
    if (status == 'accepted') c = Colors.green;
    if (status == 'pending') c = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _rideCard(Map<String, dynamic> ride) {
    final l = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xff16a34a),
          child: Icon(Icons.directions_car, color: Colors.white, size: 20),
        ),
        title: Text(ride['passengerName']?.toString() ?? l.guest),
        subtitle: Text('${l.familyRideActive} · #${ride['id']}'),
        trailing: Text(
          ride['status']?.toString() ?? '',
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
