import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_environment.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_typography.dart';

class EmbeddedGoogleMapCard extends StatefulWidget {
  final String initialAddress;
  final double initialLat;
  final double initialLng;
  final Function(String formattedAddress, LocationDetails? details) onLocationChanged;
  final String? placeholderHint;

  const EmbeddedGoogleMapCard({
    super.key,
    this.initialAddress = '',
    this.initialLat = 22.7196, // Indore center
    this.initialLng = 75.8577,
    required this.onLocationChanged,
    this.placeholderHint,
  });

  @override
  State<EmbeddedGoogleMapCard> createState() => _EmbeddedGoogleMapCardState();
}

class _EmbeddedGoogleMapCardState extends State<EmbeddedGoogleMapCard> {
  final _searchCtrl = TextEditingController();
  final _mapsService = MapsService();

  late double _currentLat;
  late double _currentLng;
  int _zoom = 18;
  String _selectedAddress = '';
  List<PlacePrediction> _predictions = [];
  bool _isSearching = false;
  bool _isReverseGeocoding = false;
  Timer? _debounceTimer;

  // Real-time pan & drag state
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  double _baseZoom = 18.0;

  @override
  void initState() {
    super.initState();
    final cached = MapsService.cachedLocation;
    if (cached != null && (widget.initialLat == 0.0 || widget.initialAddress.isEmpty)) {
      _currentLat = cached.latitude;
      _currentLng = cached.longitude;
      _selectedAddress = cached.formattedAddress;
    } else {
      _currentLat = (widget.initialLat != 0.0) ? widget.initialLat : 22.7196;
      _currentLng = (widget.initialLng != 0.0) ? widget.initialLng : 75.8577;
      _selectedAddress = widget.initialAddress;
    }
    _searchCtrl.text = '';

    if (_selectedAddress.isEmpty && MapsService.cachedLocation == null) {
      _initCurrentLocation();
    }
  }

  Future<void> _initCurrentLocation({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);
    final loc = await _mapsService.fetchCurrentLocation(forceRefresh: forceRefresh);
    if (loc != null && mounted) {
      setState(() {
        _currentLat = loc.latitude;
        _currentLng = loc.longitude;
        _selectedAddress = loc.formattedAddress;
        _isReverseGeocoding = false;
      });
      widget.onLocationChanged(loc.formattedAddress, loc);
    } else {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
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
    _searchCtrl.clear();
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
        _isSearching = false;
      });
      widget.onLocationChanged(details.formattedAddress, details);
    } else {
      if (mounted) {
        setState(() {
          _selectedAddress = pred.description;
          _isSearching = false;
        });
        widget.onLocationChanged(pred.description, null);
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    final totalDx = _dragOffset.dx;
    final totalDy = _dragOffset.dy;

    // Web Mercator scale: at latitude lat, 1 pixel represents:
    // metersPerPixel = (156543.03392 * cos(lat * pi / 180)) / (2 ^ zoom)
    // Degrees per pixel:
    // latDegPerPixel = metersPerPixel / 111320.0
    // lngDegPerPixel = metersPerPixel / (111320.0 * cos(lat * pi / 180)) = 156543.03392 / (2^zoom * 111320.0)
    final mathVal = math.pow(2.0, _zoom.toDouble());
    final cosLat = math.cos(_currentLat * math.pi / 180.0);
    final metersPerPixel = (156543.03392 * cosLat) / mathVal;

    final latDelta = (totalDy * metersPerPixel) / 111320.0;
    final lngDelta = -(totalDx * (156543.03392 / (mathVal * 111320.0)));

    final newLat = (_currentLat + latDelta).clamp(-85.0, 85.0);
    final newLng = (_currentLng + lngDelta).clamp(-180.0, 180.0);

    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
      _currentLat = newLat;
      _currentLng = newLng;
      _isReverseGeocoding = true;
    });

    final location = await _mapsService.reverseGeocode(
      latitude: newLat,
      longitude: newLng,
    );

    if (mounted) {
      final exactDetails = LocationDetails(
        latitude: newLat,
        longitude: newLng,
        formattedAddress: location?.formattedAddress ??
            '${newLat.toStringAsFixed(5)}, ${newLng.toStringAsFixed(5)}',
        street: location?.street,
        area: location?.area,
        city: location?.city,
        state: location?.state,
        pincode: location?.pincode,
      );

      setState(() {
        _isReverseGeocoding = false;
        _selectedAddress = exactDetails.formattedAddress;
      });
      widget.onLocationChanged(exactDetails.formattedAddress, exactDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map with Google Maps API key (Muted style hiding POIs like hospitals, parks, business spots)
    const mapStyle =
        '&style=feature:poi%7Cvisibility:off&style=feature:transit%7Cvisibility:simplified';
    final staticMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap?center=$_currentLat,$_currentLng&zoom=$_zoom&size=640x360&scale=2&markers=color:red%7C$_currentLat,$_currentLng$mapStyle&key=${AppEnvironment.googleMapsApiKey}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Input Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                icon: const Icon(Icons.search, size: 18.0, color: Color(0xFF64748B)),
                hintText: widget.placeholderHint ?? 'Search for an area, building or landmark',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.0),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Color(0xFF059669),
                          ),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16.0, color: Color(0xFF64748B)),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null),
              ),
            ),
          ),

          // Predictions Dropdown (inline if user typed)
          if (_predictions.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Container(
              constraints: const BoxConstraints(maxHeight: 180.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 8.0, offset: Offset(0, 4)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                itemCount: _predictions.length,
                separatorBuilder: (_, __) => const Divider(height: 1.0, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final pred = _predictions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 16.0),
                    title: Text(
                      pred.mainText,
                      style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    subtitle: Text(
                      pred.secondaryText,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _onPredictionSelected(pred),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12.0),

          // 2. Interactive Pannable Google Map Tile Box
          GestureDetector(
            onScaleStart: (details) {
              _onPanStart(DragStartDetails(globalPosition: details.focalPoint));
              _baseZoom = _zoom.toDouble();
            },
            onScaleUpdate: (details) {
              if (details.pointerCount == 1) {
                _onPanUpdate(DragUpdateDetails(
                  globalPosition: details.focalPoint,
                  delta: details.focalPointDelta,
                ));
              } else if (details.pointerCount >= 2 && details.scale != 1.0) {
                final newZoom = (_baseZoom + (details.scale - 1.0) * 3).round().clamp(3, 20);
                if (newZoom != _zoom) {
                  setState(() {
                    _zoom = newZoom;
                  });
                }
              }
            },
            onScaleEnd: (details) {
              _onPanEnd(DragEndDetails(velocity: details.velocity));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Container(
                height: 250.0,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pannable Google Map Canvas
                    Transform.translate(
                      offset: _dragOffset,
                      child: Image.network(
                        staticMapUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://static-maps.yandex.ru/1.x/?ll=$_currentLng,$_currentLat&z=$_zoom&l=map&size=600,300',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),

                    // Floating Center Pin Marker with lift effect on dragging
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      top: _isDragging ? 88.0 : 96.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFEF4444),
                            size: 40.0,
                            shadows: [
                              Shadow(
                                color: Color(0x33000000),
                                blurRadius: 6.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          // Pin Shadow on ground
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: _isDragging ? 14.0 : 8.0,
                            height: 4.0,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floating Pill Badge ("TAP/DRAG THE MAP TO DROP A PIN")
                    if (!_isDragging && !_isReverseGeocoding && _selectedAddress.isEmpty)
                      Positioned(
                        bottom: 12.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 8.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'DRAG MAP TO MOVE PIN',
                            style: AppTypography.monoLabel.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),

                    // Live Dragging / Geocoding Status Chip
                    if (_isDragging || _isReverseGeocoding)
                      Positioned(
                        top: 10.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14.0),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 6.0),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isReverseGeocoding)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6.0),
                                  child: SizedBox(
                                    width: 12.0,
                                    height: 12.0,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                  ),
                                ),
                              Text(
                                _isDragging ? 'Move pin to desired spot' : 'Fetching address...',
                                style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Zoom & Location Controls on the right
                    Positioned(
                      right: 8.0,
                      bottom: 8.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1F000000), blurRadius: 4.0),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _zoom = (_zoom + 1).clamp(3, 20)),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.add, size: 16.0, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
                            InkWell(
                              onTap: () => setState(() => _zoom = (_zoom - 1).clamp(3, 20)),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.remove, size: 16.0, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
                            InkWell(
                              onTap: () => _initCurrentLocation(forceRefresh: true),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.my_location, size: 16.0, color: Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10.0),

          // 3. Selected Address Row / Location Info
          if (_selectedAddress.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF059669), size: 16.0),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    _selectedAddress,
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF475569),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 15.0),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    'Location is blocked. Allow it in your device settings, or pin the spot on the map.',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFFD97706),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
