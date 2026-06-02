// screens/sos/sos_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../providers/theme_provider.dart';
import 'dart:math';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool _isSending = false;
  bool _alertSent = false;
  List<Map<String, dynamic>> _myAlerts = [];
  bool _loadingAlerts = true;

  // Location
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;
  String? _locationError;

  // Emergency Services
  List<EmergencyService> _nearbyServices = [];
  bool _loadingServices = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _successController;
  late Animation<double> _successScaleAnim;
  late AnimationController _shakeController;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _initLocation();
    _loadMyAlerts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _shakeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _loadingLocation = false;
        _locationError = null;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _loadMyAlerts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('sos_alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      setState(() {
        _myAlerts = List<Map<String, dynamic>>.from(data);
        _loadingAlerts = false;
      });
    } catch (_) {
      setState(() => _loadingAlerts = false);
    }
  }

  Future<void> _fetchNearbyServices() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enable location to find nearby services'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _loadingServices = true);

    try {
      // Call your backend API to fetch nearby services
      // This should use Google Places API or your own backend
      final response = await supabase
          .from('emergency_services')
          .select()
          .or('type.eq.hospital,type.eq.police,type.eq.ambulance')
          .gte('lat', _latitude! - 0.1)
          .lte('lat', _latitude! + 0.1)
          .gte('lng', _longitude! - 0.1)
          .lte('lng', _longitude! + 0.1)
          .limit(15);

      List<EmergencyService> services = [];
      for (var item in response) {
        services.add(EmergencyService.fromMap(item));
      }

      // Sort by distance
      services.sort((a, b) {
        double distA = _calculateDistance(
          _latitude!,
          _longitude!,
          a.lat,
          a.lng,
        );
        double distB = _calculateDistance(
          _latitude!,
          _longitude!,
          b.lat,
          b.lng,
        );
        return distA.compareTo(distB);
      });

      setState(() {
        _nearbyServices = services;
        _loadingServices = false;
        _updateMapMarkers();
      });

      _showServicesBottomSheet();
    } catch (e) {
      setState(() => _loadingServices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading services: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _updateMapMarkers() {
    _markers.clear();

    // User location marker
    if (_latitude != null && _longitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_latitude!, _longitude!),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Service markers
    for (var i = 0; i < _nearbyServices.length; i++) {
      final service = _nearbyServices[i];
      BitmapDescriptor markerColor;

      switch (service.type.toLowerCase()) {
        case 'hospital':
          markerColor = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
          break;
        case 'police':
          markerColor = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
          break;
        case 'ambulance':
          markerColor = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          );
          break;
        default:
          markerColor = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          );
      }

      _markers.add(
        Marker(
          markerId: MarkerId('service_$i'),
          position: LatLng(service.lat, service.lng),
          infoWindow: InfoWindow(title: service.name, snippet: service.type),
          icon: markerColor,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _showServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildServicesBottomSheet(),
    );
  }

  Widget _buildServicesBottomSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F4)
        : const Color(0xFF0D1117);
    final textSecondary = isDark
        ? const Color(0xFF4A5478)
        : const Color(0xFF8892A4);
    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: surfaceBorder, width: 0.5)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Nearby Emergency Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loadingServices)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                )
              else if (_nearbyServices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No emergency services found nearby',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                )
              else
                ..._nearbyServices.map(
                  (service) => _buildServiceCard(
                    service,
                    isDark,
                    surface,
                    surfaceBorder,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              const SizedBox(height: 16),
              if (_latitude != null && _longitude != null)
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_latitude!, _longitude!),
                        zoom: 14,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    EmergencyService service,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    Color typeColor;
    IconData typeIcon;

    switch (service.type.toLowerCase()) {
      case 'hospital':
        typeColor = Colors.redAccent;
        typeIcon = Icons.local_hospital;
        break;
      case 'police':
        typeColor = Colors.blueAccent;
        typeIcon = Icons.local_police;
        break;
      case 'ambulance':
        typeColor = Colors.orangeAccent;
        typeIcon = Icons.emergency;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: typeColor.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${service.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchCall(service.phone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: typeColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: typeColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Call',
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchMaps(service.lat, service.lng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: typeColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions, color: typeColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final uri = Uri(scheme: 'geo', path: '$lat,$lng', query: 'q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSOS() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Waiting for location...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await supabase.from('sos_alerts').insert({
        'user_id': userId,
        'latitude': _latitude,
        'longitude': _longitude,
        'status': 'active',
      });
      setState(() {
        _isSending = false;
        _alertSent = true;
      });
      _successController.forward(from: 0);
      await _loadMyAlerts();

      // Automatically fetch nearby services
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _fetchNearbyServices();
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _cancelAlert(String alertId) async {
    try {
      await supabase
          .from('sos_alerts')
          .update({'status': 'cancelled'})
          .eq('id', alertId);
      await _loadMyAlerts();
      if (mounted) {
        setState(() => _alertSent = false);
        _successController.reverse();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F4)
        : const Color(0xFF0D1117);
    final textSecondary = isDark
        ? const Color(0xFF4A5478)
        : const Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded, color: accentColor, size: 20),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              const Icon(
                Icons.emergency_outlined,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Emergency SOS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use only in genuine emergency situations. False alerts may prevent real emergencies from being addressed.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFB0B8D0)
                            : const Color(0xFF334155),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Location Status
            if (_locationError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: TextStyle(
                          color: Colors.orange.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _initLocation,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.orange.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_loadingLocation)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.blue.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fetching your location...',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else if (_latitude != null && _longitude != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location ready: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            // SOS Button
            Center(
              child: _alertSent
                  ? ScaleTransition(
                      scale: _successScaleAnim,
                      child: _buildSuccessState(
                        accentColor,
                        isDark,
                        textPrimary,
                        textSecondary,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Transform.scale(
                        scale: _isSending ? 1.0 : _pulseAnim.value,
                        child: _buildSOSButton(isDark),
                      ),
                    ),
            ),

            const SizedBox(height: 40),

            // Info cards
            _buildInfoCard(
              Icons.location_on_outlined,
              'Location Sharing',
              'Your GPS coordinates will be sent with the alert to help responders locate you.',
              Colors.blueAccent,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.local_hospital_outlined,
              'Find Services',
              'Instantly locate nearby hospitals, police stations, and ambulances with one tap.',
              Colors.redAccent,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.people_outline_rounded,
              'Alert Broadcast',
              'Nearby Bhromon users and emergency contacts will be notified immediately.',
              Colors.orange,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.history_outlined,
              'Alert History',
              'All your SOS alerts are logged and can be reviewed by you.',
              accentColor,
              isDark,
              surface,
              surfaceBorder,
              textPrimary,
              textSecondary,
            ),

            // Past alerts
            if (_myAlerts.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    'Recent Alerts',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._myAlerts.map(
                (alert) => _buildAlertItem(
                  alert,
                  accentColor,
                  isDark,
                  surface,
                  surfaceBorder,
                  textPrimary,
                  textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(bool isDark) {
    return GestureDetector(
      onTap: _isSending ? null : _sendSOS,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.15),
                width: 12,
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.25),
                width: 6,
              ),
            ),
          ),
          // Main button
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: _isSending
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
    Color accentColor,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.15),
                  width: 12,
                ),
              ),
            ),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1E2A42)
                    : const Color(0xFFEEF0F5),
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.greenAccent,
                size: 44,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Alert Sent!',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Help is on the way. Stay calm.',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _fetchNearbyServices,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  'Find Nearby Services',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_myAlerts.isNotEmpty && _myAlerts.first['status'] == 'active')
          GestureDetector(
            onTap: () => _cancelAlert(_myAlerts.first['id']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'Cancel Alert',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String desc,
    Color iconColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: iconColor.withOpacity(0.2), width: 0.5),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(
    Map<String, dynamic> alert,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final status = alert['status'] as String? ?? 'active';
    final createdAt = alert['created_at'] as String? ?? '';
    final isActive = status == 'active';

    Color statusColor;
    String statusLabel;
    if (status == 'active') {
      statusColor = Colors.redAccent;
      statusLabel = 'Active';
    } else if (status == 'cancelled') {
      statusColor = textSecondary;
      statusLabel = 'Cancelled';
    } else {
      statusColor = Colors.greenAccent.shade400;
      statusLabel = 'Resolved';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS Alert',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: statusColor.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _cancelAlert(alert['id']),
              child: Icon(Icons.close_rounded, color: textSecondary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// Emergency Service Model
class EmergencyService {
  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final double distance;

  EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    this.distance = 0,
  });

  factory EmergencyService.fromMap(Map<String, dynamic> map) {
    return EmergencyService(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      type: map['type'] ?? 'Unknown',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
    );
  }
}
