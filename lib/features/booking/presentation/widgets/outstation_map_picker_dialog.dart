import 'package:flutter/material.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'embedded_google_map_card.dart';

class OutstationMapPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final Function(
    double lat,
    double lng,
    String address,
    LocationDetails? details,
  ) onLocationConfirmed;

  const OutstationMapPickerDialog({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onLocationConfirmed,
  });

  @override
  State<OutstationMapPickerDialog> createState() =>
      _OutstationMapPickerDialogState();
}

class _OutstationMapPickerDialogState extends State<OutstationMapPickerDialog> {
  late double _selectedLat;
  late double _selectedLng;
  String _selectedAddress = '';
  LocationDetails? _selectedDetails;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: screenHeight * 0.88,
        ),
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Pickup Location',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF64748B),
                    size: 22.0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14.0),

            // Embedded Real Google Map Card (Pinch Zoom, Pan, Live Search, GPS)
            EmbeddedGoogleMapCard(
              initialLat: _selectedLat,
              initialLng: _selectedLng,
              placeholderHint: 'Search for area or landmark',
              onLocationChanged: (address, details) {
                setState(() {
                  _selectedAddress = address;
                  _selectedDetails = details;
                  if (details != null) {
                    _selectedLat = details.latitude;
                    _selectedLng = details.longitude;
                  }
                });
              },
            ),

            const SizedBox(height: 16.0),

            // Bottom Actions (Coordinates, Cancel & Confirm)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedLat != 0.0 && _selectedLng != 0.0
                        ? '${_selectedLat.toStringAsFixed(4)}, ${_selectedLng.toStringAsFixed(4)}'
                        : 'Select Location',
                    style: AppTypography.monoData.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 10.0,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                      ),
                      onPressed: () {
                        if (_selectedLat == 0.0 || _selectedLng == 0.0) {
                          AppSnackBar.showError(
                            context,
                            AppLocalizations.of(context)!.pickupLocation,
                          );
                          return;
                        }
                        widget.onLocationConfirmed(
                          _selectedLat,
                          _selectedLng,
                          _selectedAddress,
                          _selectedDetails,
                        );
                        Navigator.of(context).pop();
                      },
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
