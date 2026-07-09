import 'package:flutter/material.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../account/familyprofile/familyprofile_screen.dart';
import '../promotions/promotions_screen.dart';
import '../referrals/referral_screen.dart';
import '../split_fare/split_fare_invites_screen.dart';

/// Hub for rider perks — family, promos, referrals (no fake subscription plans).
class RiderBenefitsScreen extends StatelessWidget {
  const RiderBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return A11yScreen(
      label: local.subscriptions,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Text(local.benefitsTitle),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              local.benefitsHeadline,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              local.benefitsDesc,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            _BenefitTile(
              icon: Icons.family_restroom_outlined,
              title: local.familyProfile,
              subtitle: local.benefitsFamilySubtitle,
              color: Colors.indigo,
              onTap: () => _open(context, const FamilyProfileScreen()),
            ),
            _BenefitTile(
              icon: Icons.local_offer_outlined,
              title: local.promotions,
              subtitle: local.benefitsPromosSubtitle,
              color: Colors.orange,
              onTap: () => _open(context, const PromotionsScreen()),
            ),
            _BenefitTile(
              icon: Icons.card_giftcard_outlined,
              title: local.referralTitle,
              subtitle: local.benefitsReferralSubtitle,
              color: Colors.purple,
              onTap: () => _open(context, const ReferralScreen()),
            ),
            _BenefitTile(
              icon: Icons.people_outline,
              title: local.splitFareInvitesTitle,
              subtitle: local.benefitsSplitFareSubtitle,
              color: Colors.teal,
              onTap: () => _open(context, const SplitFareInvitesScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black12,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
