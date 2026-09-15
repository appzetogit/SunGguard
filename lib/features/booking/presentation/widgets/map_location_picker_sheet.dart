import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_typography.dart';

class MapLocationPickerSheet extends StatefulWidget {
  final String title;
  final String initialAddress;
  final Function(LocationDetails location) onLocationSelected;

  const MapLocationPickerSheet({
    super.key,
    required this.title,
    this.initialAddress = '',
    required this.onLocationSelected,
  });

  static Future<LocationDetails?> show(
    BuildContext context, {
    required String title,
    String initialAddress = '',
  }) {
    return showModalBottomSheet<LocationDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapLocationPickerSheet(
        title: title,
        initialAddress: initialAddress,
        onLocationSelected: (location) => Navigator.of(ctx).pop(location),
      ),
    );
  }

  @override
  State<MapLocationPickerSheet> createState() => _MapLocationPickerSheetState();
}

class _MapLocationPickerSheetState extends State<MapLocationPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _mapsService = MapsService();

  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  double _currentLat = 22.724; // Default to Indore
  double _currentLng = 75.882;
  int _zoom = 15;
  String _selectedAddress = '';
  LocationDetails? _selectedDetails;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress.isNotEmpty
        ? widget.initialAddress
        : '17/C, New Palasia, Indore, Madhya Pradesh 452001, India';
    _searchCtrl.text = widget.initialAddress;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _mapsService.getPlacePredictions(query);
      if (mounted) {
        setState(() {
          _predictions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _onPredictionSelected(PlacePrediction pred) async {
    _searchCtrl.text = pred.description;
    setState(() {
      _predictions = [];
      _isSearching = true;
    });

    final details = await _mapsService.getPlaceDetails(pred.placeId);
    if (details != null && mounted) {
      setState(() {
        _currentLat = details.latitude;
        _currentLng = details.longitude;
        _selectedAddress = details.formattedAddress;
        _selectedDetails = details;
        _isSearching = false;
      });
    } else {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staticMapUrl = _mapsService.getStaticMapUrl(
      latitude: _currentLat,
      longitude: _currentLng,
      zoom: _zoom,
      width: 600,
      height: 350,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12.0),
          Container(
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(height: 14.0),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.headingLarge.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF64748B),
                    size: 22.0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                      size: 20.0,
                    ),
                  ),
                  hintText: 'Search street, building or locality',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16.0,
                            height: 16.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Color(0xFF059669),
                            ),
                          ),
                        )
                      : (_searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18.0,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null),
                ),
              ),
            ),
          ),

          // Autocomplete Predictions List OR Map
          Expanded(
            child: _predictions.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1.0, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final pred = _predictions[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF2563EB),
                            size: 18.0,
                          ),
                        ),
                        title: Text(
                          pred.mainText,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          pred.secondaryText,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        onTap: () => _onPredictionSelected(pred),
                      );
                    },
                  )
                : Stack(
                    children: [
                      // Google Static / Interactive Map
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFFE2E8F0),
                          child: Image.network(
                            staticMapUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.map,
                                    size: 48.0,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Map Preview',
                                    style: AppTypography.monoLabel.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Center Marker Pin
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 24.0),
                          child: Icon(
                            Icons.location_on,
                            color: Color(0xFFEF4444),
                            size: 42.0,
                          ),
                        ),
                      ),

                      // Zoom & Location Controls
                      Positioned(
                        right: 16.0,
                        bottom: 16.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  size: 18.0,
                                  color: Color(0xFF0F172A),
                                ),
                                onPressed: () => setState(
                                  () => _zoom = (_zoom + 1).clamp(3, 20),
                                ),
                              ),
                              const Divider(
                                height: 1.0,
                                color: Color(0xFFE2E8F0),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  size: 18.0,
                                  color: Color(0xFF0F172A),
                                ),
                                onPressed: () => setState(
                                  () => _zoom = (_zoom - 1).clamp(3, 20),
                                ),
                              ),
                              const Divider(
                                height: 1.0,
                                color: Color(0xFFE2E8F0),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  size: 18.0,
                                  color: Color(0xFF059669),
                                ),
                                onPressed: () {
                                  // Default GPS center
                                  setState(() {
                                    _currentLat = 22.724;
                                    _currentLng = 75.882;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Selected Address & Confirm Button
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 20.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF059669),
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _selectedAddress,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                SizedBox(
                  width: double.infinity,
                  height: 48.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      final details =
                          _selectedDetails ??
                          LocationDetails(
                            latitude: _currentLat,
                            longitude: _currentLng,
                            formattedAddress: _selectedAddress,
                          );
                      widget.onLocationSelected(details);
                    },
                    child: Text(
                      'CONFIRM THIS LOCATION',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
