import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../services/rider_service.dart';

class WaterTankerOrderScreen extends StatefulWidget {
  const WaterTankerOrderScreen({super.key});
  @override
  State<WaterTankerOrderScreen> createState() => _WaterTankerOrderScreenState();
}

class _WaterTankerOrderScreenState extends State<WaterTankerOrderScreen> {
  int barrels = 1;
  String? waterType;
  String location = '';
  bool _loading = false;
  bool _pricingLoad = false;
  double? _total;
  String? _zoneLabel;

  String get eta => '${20 + barrels * 3} - ${30 + barrels * 4} min';

  bool get _valid => waterType != null && location.isNotEmpty && _total != null;

  @override
  void initState() {
    super.initState();
    _refreshPrice();
  }

  Future<void> _refreshPrice() async {
    setState(() => _pricingLoad = true);
    try {
      final q = await RiderService.instance.estimateSpecialService(
        type: 'water_tanker',
        barrels: barrels,
      );
      if (!mounted) return;
      setState(() {
        _total = (q['total'] as num?)?.toDouble();
        _zoneLabel = q['zone']?['labelAr']?.toString();
      });
    } catch (_) {
      if (mounted) setState(() => _total = null);
    } finally {
      if (mounted) setState(() => _pricingLoad = false);
    }
  }

  Future<void> _place() async {
    if (!_valid || _total == null) return;
    setState(() => _loading = true);

    final result = await RiderService.instance.placeSpecialOrder(
      type: 'water_tanker',
      details: {'barrels': barrels, 'waterType': waterType},
      location: location,
      totalPrice: _total!,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Order Placed!'),
          content: Text('Order #${result['id']} confirmed.\nETA: $eta'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: Text(l.waterTankerTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barrels
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.barrels,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (barrels > 1) {
                            setState(() => barrels--);
                            _refreshPrice();
                          }
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '$barrels',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => barrels++);
                          _refreshPrice();
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Water Type
            _card(
              child: DropdownButtonFormField<String>(
                initialValue: waterType,
                decoration: InputDecoration(
                  labelText: l.waterType,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'drinking',
                    child: Text(l.drinkingWater),
                  ),
                  DropdownMenuItem(
                    value: 'regular',
                    child: Text(l.regularWater),
                  ),
                  DropdownMenuItem(
                    value: 'agriculture',
                    child: Text(l.agriculturalWater),
                  ),
                ],
                onChanged: (v) => setState(() => waterType = v),
              ),
            ),

            const SizedBox(height: 14),

            // Location
            _card(
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: location.isNotEmpty ? Colors.green : Colors.grey,
                ),
                title: Text(l.location),
                subtitle: Text(location.isEmpty ? l.selectLocation : location),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => setState(() => location = 'GPS Location'),
                  child: Text(
                    l.now,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.estimatedPrice,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_zoneLabel != null)
                    Text(
                      _zoneLabel!,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _pricingLoad
                        ? '...'
                        : CurrencyUtils.formatSyp(_total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.eta,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        eta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _valid ? Colors.black : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: (_valid && !_loading) ? _place : null,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l.placeOrder,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    child: child,
  );
}
