import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../services/rider_service.dart';

class MovingServiceScreen extends StatefulWidget {
  const MovingServiceScreen({super.key});
  @override
  State<MovingServiceScreen> createState() => _MovingServiceScreenState();
}

class _MovingServiceScreenState extends State<MovingServiceScreen> {
  String? itemsType, vehicle;
  int workers = 1;
  String location = '';
  bool _loading = false;
  bool _pricingLoad = false;
  double? _total;
  String? _zoneLabel;

  String get eta => '${30 + workers * 5} - ${50 + workers * 7} min';
  bool get _valid =>
      itemsType != null && vehicle != null && location.isNotEmpty && _total != null;

  @override
  void initState() {
    super.initState();
    _refreshPrice();
  }

  Future<void> _refreshPrice() async {
    if (vehicle == null) {
      setState(() => _total = null);
      return;
    }
    setState(() => _pricingLoad = true);
    try {
      final q = await RiderService.instance.estimateSpecialService(
        type: 'moving',
        vehicleSize: vehicle,
        workers: workers,
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
      type: 'moving',
      details: {
        'itemsType': itemsType,
        'vehicleSize': vehicle,
        'workers': workers,
      },
      location: location,
      totalPrice: _total!,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result != null) {
      final l = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: Text(l.orderPlacedTitle),
          content: Text(
            '${l.orderPlacedBody(result['id'].toString())}\n${l.orderEta(eta)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: Text(l.done),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.orderPlaceFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.movingTitle,
      child: Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.movingTitle)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              DropdownButtonFormField(
                initialValue: itemsType,
                decoration: InputDecoration(
                  labelText: l.itemsType,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'furniture',
                    child: Text(l.furniture),
                  ),
                  DropdownMenuItem(value: 'boxes', child: Text(l.boxes)),
                  DropdownMenuItem(value: 'mixed', child: Text(l.mixed)),
                ],
                onChanged: (v) => setState(() => itemsType = v),
              ),
            ),
            const SizedBox(height: 12),

            _card(
              DropdownButtonFormField(
                initialValue: vehicle,
                decoration: InputDecoration(
                  labelText: l.vehicleSize,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'small', child: Text(l.smallTruck)),
                  DropdownMenuItem(value: 'medium', child: Text(l.mediumTruck)),
                  DropdownMenuItem(value: 'large', child: Text(l.largeTruck)),
                ],
                onChanged: (v) {
                  setState(() => vehicle = v);
                  _refreshPrice();
                },
              ),
            ),
            const SizedBox(height: 12),

            _card(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.workers,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (workers > 1) {
                            setState(() => workers--);
                            _refreshPrice();
                          }
                        },
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '$workers',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => workers++);
                          _refreshPrice();
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _card(
              ListTile(
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
                  onPressed: () => setState(() => location = l.gpsLocation),
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
                  colors: [Colors.orange.shade600, Colors.orange.shade800],
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
                    Text(_zoneLabel!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    _pricingLoad ? '...' : CurrencyUtils.formatSyp(_total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
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

            A11yButton(
              label: l.placeOrder,
              enabled: _valid && !_loading,
              child: SizedBox(
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
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    child: child,
  );
}
