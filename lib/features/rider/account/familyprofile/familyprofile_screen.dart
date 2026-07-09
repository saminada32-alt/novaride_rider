import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/a11y.dart';
import '../../../../l10n/app_localizations.dart';
import '../my_account_all/provider/account_provider.dart';
import 'family_service.dart';
import 'model/family_member.dart';

const int _kMaxFamilyMembers = 9;
const _kFamilyIntroSeenKey = 'family_intro_seen';

class FamilyProfileScreen extends StatefulWidget {
  const FamilyProfileScreen({super.key});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen>
    with SingleTickerProviderStateMixin {
  FamilyHub? _hub;
  bool _loading = true;
  bool _saving = false;
  bool _showHub = false;
  bool _showAddForm = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _relation;
  String _inviteRole = 'parent';

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final hub = await FamilyApiService.instance.getHub();
      final prefs = await SharedPreferences.getInstance();
      final introSeen = prefs.getBool(_kFamilyIntroSeenKey) ?? false;
      final hasFamily = hub.members.where((m) => !m.isOwner).isNotEmpty ||
          hub.pendingInvites.isNotEmpty;
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _loading = false;
        _showHub = true;
      });
      context.read<AccountProvider>().familyMembers =
          hub.members.map((m) => m.toJson()).toList();
      if (!hasFamily && !introSeen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showIntroSheet();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFamilyIntroSeenKey, true);
    if (mounted) setState(() {});
  }

  void _openSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        _animCtrl.forward(from: 0);
        return FadeTransition(
          opacity: _fade,
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xff16a34a);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: c,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showIntroSheet() {
    final l = AppLocalizations.of(context)!;
    _openSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/family_profile.jpg',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: const Color(0xff16a34a).withValues(alpha: 0.15),
                child: const Icon(
                  Icons.family_restroom,
                  size: 72,
                  color: Color(0xff16a34a),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.inviteTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l.inviteSubtitle),
          const SizedBox(height: 16),
          _featureRow(Icons.shield, l.safety, l.safetyDesc),
          const SizedBox(height: 10),
          _featureRow(Icons.location_on, l.track, l.trackDesc),
          const SizedBox(height: 10),
          _featureRow(Icons.payment, l.pay, l.payDesc),
          const SizedBox(height: 20),
          _primaryButton(l.createFamilyProfile, () {
            Navigator.pop(context);
            _showLoveSheet();
          }),
        ],
      ),
    );
  }

  void _showLoveSheet() {
    final l = AppLocalizations.of(context)!;
    _openSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/loves.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xff16a34a).withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.family_restroom,
                      size: 72,
                      color: Color(0xff16a34a),
                    ),
                  ),
                ),
                Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
                const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 56,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.inviteAdultsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l.inviteAdultsSubtitle),
          const SizedBox(height: 16),
          _featureRow(Icons.payment, l.inviteAdultsFeature1, l.inviteAdultsFeature1Desc),
          const SizedBox(height: 10),
          _featureRow(Icons.account_balance_wallet, l.inviteAdultsFeature2, l.inviteAdultsFeature2Desc),
          const SizedBox(height: 10),
          _featureRow(Icons.location_on, l.inviteAdultsFeature3, l.inviteAdultsFeature3Desc),
          const SizedBox(height: 10),
          _featureRow(Icons.chat_bubble_outline, l.inviteAdultsFeature4, l.inviteAdultsFeature4Desc),
          const SizedBox(height: 24),
          _primaryButton(
            l.createFamilyProfile,
            () async {
              Navigator.pop(context);
              await _markIntroSeen();
            },
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String desc) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xff16a34a), size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    ],
  );

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

  void _prepareInvite({String role = 'member', String? relation}) {
    final l = AppLocalizations.of(context)!;
    if (_hub != null && _hub!.members.length >= _kMaxFamilyMembers) {
      _snack(l.familyMaxMembers, error: true);
      return;
    }
    _inviteRole = role;
    _relation = relation;
    _nameCtrl.clear();
    _phoneCtrl.clear();
    setState(() => _showAddForm = true);
  }

  Future<void> _sendInvite(AppLocalizations l) async {
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
      await _load();
      if (!mounted) return;
      setState(() {
        _showHub = true;
        _showAddForm = false;
      });
      _snack(l.familyInviteSent);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildInviteForm(AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.addFamilyMembers,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
            value: _relation,
            decoration: InputDecoration(
              labelText: l.relation,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              DropdownMenuItem(value: 'wife', child: Text(l.wife)),
              DropdownMenuItem(value: 'husband', child: Text(l.husband)),
              DropdownMenuItem(value: 'mother', child: Text(l.mother)),
              DropdownMenuItem(value: 'father', child: Text(l.father)),
              DropdownMenuItem(value: 'son', child: Text(l.son)),
              DropdownMenuItem(value: 'daughter', child: Text(l.daughter)),
              DropdownMenuItem(value: 'brother', child: Text(l.brother)),
              DropdownMenuItem(value: 'sister', child: Text(l.sister)),
            ],
            onChanged: (v) => setState(() => _relation = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _sendInvite(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff16a34a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l.familySendInvite,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHub(AppLocalizations l) {
    if (_hub == null) {
      return Center(child: Text(l.actionFailed));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_hub!.pendingInvites.isNotEmpty) ...[
            _sectionTitle(l.familyPendingInvites),
            ..._hub!.pendingInvites.map((inv) => _inviteCard(l, inv)),
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
                    () => _prepareInvite(role: 'parent', relation: 'mother'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickInviteBtn(
                    l.familyInviteFather,
                    Icons.male,
                    () => _prepareInvite(role: 'parent', relation: 'father'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_showAddForm && _hub!.canManage) _buildInviteForm(l),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.familyProfile,
      child: Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.familyProfile)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showHub
          ? _buildHub(l)
          : Center(child: Text(l.actionFailed)),
      floatingActionButton: _showHub &&
              _hub != null &&
              _hub!.canManage &&
              _hub!.members.length < _kMaxFamilyMembers
          ? FloatingActionButton.extended(
              onPressed: () => _prepareInvite(role: 'member'),
              backgroundColor: const Color(0xff16a34a),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l.addMember),
            )
          : null,
    ),
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
