import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// Toggles for `GET|PATCH /api/push/preferences`.
///
/// The endpoints have always existed and the app had no screen for them, so a
/// customer could not turn off promotional pushes without disabling
/// notifications for the whole app at the OS level.
class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final _client = ApiClient.createDefault();

  bool _isLoading = true;
  bool _orderUpdates = true;
  bool _deliveryUpdates = true;
  bool _promotions = true;

  /// Which key is mid-flight, so only that row shows a spinner.
  String? _savingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _client.get(ApiEndpoints.pushPreferences);
      final data = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
      if (data is Map && mounted) {
        setState(() {
          // Absent means "on" — the server defaults every channel to enabled.
          _orderUpdates = data['orderUpdates'] != false;
          _deliveryUpdates = data['deliveryUpdates'] != false;
          _promotions = data['promotions'] != false;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _update(String key, bool value) async {
    // Optimistic: flip immediately, roll back if the server refuses.
    final previous = _readKey(key);
    setState(() {
      _writeKey(key, value);
      _savingKey = key;
    });

    try {
      await _client.patch(
        ApiEndpoints.pushPreferences,
        data: {key: value},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _writeKey(key, previous));
      AppSnackBar.showError(context, "Couldn't save that preference");
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  bool _readKey(String key) => switch (key) {
        'orderUpdates' => _orderUpdates,
        'deliveryUpdates' => _deliveryUpdates,
        _ => _promotions,
      };

  void _writeKey(String key, bool value) {
    switch (key) {
      case 'orderUpdates':
        _orderUpdates = value;
      case 'deliveryUpdates':
        _deliveryUpdates = value;
      default:
        _promotions = value;
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18.0,
            color: Color(0xFF0F172A),
          ),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: Text(
          'Notification settings',
          style: AppTypography.headingLarge.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildTile(
                  keyName: 'orderUpdates',
                  title: 'Booking updates',
                  subtitle: 'Confirmations, cancellations and refunds',
                  value: _orderUpdates,
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 12.0),
                _buildTile(
                  keyName: 'deliveryUpdates',
                  title: 'Delivery updates',
                  subtitle: 'Rider assigned, picked up, delivered',
                  value: _deliveryUpdates,
                  icon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: 12.0),
                _buildTile(
                  keyName: 'promotions',
                  title: 'Offers and promotions',
                  subtitle: 'Discounts and occasional announcements',
                  value: _promotions,
                  icon: Icons.local_offer_outlined,
                ),
              ],
            ),
    );
  }

  Widget _buildTile({
    required String keyName,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
  }) {
    final isSaving = _savingKey == keyName;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, size: 20.0, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isSaving)
            const SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Color(0xFF059669),
              ),
            )
          else
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF059669),
              onChanged: (next) => _update(keyName, next),
            ),
        ],
      ),
    );
  }
}
