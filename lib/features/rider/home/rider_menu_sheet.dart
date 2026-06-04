import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rider_menu_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../account/my_account_all/my_account_screen.dart';
import '../payments/payments_screen.dart';
import '../promotions/promotions_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../rides/my_rides_screen.dart';
import '../safety/safety_screen.dart';
import '../support/support_screen.dart';
import '../about/about_screen.dart';
import '../notifications/notifications_screen.dart';
import '../expense/ride_expense_screen.dart';
import '../water_tanker/water_tanker_screen.dart';
import '../car_wash/car_wash_screen.dart';
import '../moving_service/moving_service_screen.dart';

class RiderMenuSheet extends StatelessWidget {
  const RiderMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().passenger;

    final name = [
      user?.firstName,
      user?.lastName,
    ].where((s) => s?.isNotEmpty == true).join(' ');
    final phone = user?.phone ?? '';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: Stack(
        children: [
          Container(color: Colors.white),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => _go(context, const MyAccountScreen()),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.transparent,
                              child: ProfileAvatar(
                                imageUrl: user?.profileImageUrl,
                                name: name.isNotEmpty ? name : local.guest,
                                radius: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty ? name : local.guest,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    _section([
                      RiderMenuItem(
                        icon: Icons.notifications_outlined,
                        title: local.notificationsTitle,
                        onTap: () => _go(context, const NotificationsScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.person_outline,
                        title: local.myAccount,
                        onTap: () => _go(context, const MyAccountScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.payment,
                        title: local.payment,
                        onTap: () => _go(context, const PaymentScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.local_offer_outlined,
                        title: local.promotions,
                        onTap: () => _go(context, const PromotionsScreen()),
                      ),
                    ]),

                    _section([
                      RiderMenuItem(
                        icon: Icons.water_damage_outlined,
                        title: local.waterTankerTitle,
                        onTap: () =>
                            _go(context, const WaterTankerOrderScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.local_car_wash,
                        title: local.carWashTitle,
                        onTap: () => _go(context, const CarWashOrderScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.car_repair,
                        title: local.movingTitle,
                        onTap: () => _go(context, const MovingServiceScreen()),
                      ),
                    ]),

                    _section([
                      RiderMenuItem(
                        icon: Icons.subscriptions_outlined,
                        title: local.subscriptions,
                        onTap: () => _go(context, const SubscriptionsScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.history,
                        title: local.myRides,
                        onTap: () => _go(context, const MyRidesScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.security_outlined,
                        title: local.safety,
                        onTap: () => _go(context, const SafetyScreen()),
                      ),
                    ]),

                    _section([
                      RiderMenuItem(
                        icon: Icons.receipt_long,
                        title: local.rideExpenses,
                        onTap: () => _go(context, const RideExpensesScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.support_agent,
                        title: local.support,
                        onTap: () => _go(context, const SupportScreen()),
                      ),
                      RiderMenuItem(
                        icon: Icons.info_outline,
                        title: local.about,
                        onTap: () => _go(context, const AboutScreen()),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(List<Widget> items) =>
      Column(children: [...items, const Divider(height: 24)]);

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

