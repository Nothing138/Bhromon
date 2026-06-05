// screens/sos/sos_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../../providers/theme_provider.dart';

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

  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;
  String? _locationError;

  List<EmergencyService> _nearbyServices = [];
  bool _loadingServices = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _successController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initLocation();
    _loadMyAlerts();
  }

  void _setupAnimations() {
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;

    setState(() => _loadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationError = 'Location permission denied';
              _loadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = 'Please enable location in settings';
            _loadingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _loadingLocation = false;
          _locationError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Location error';
          _loadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadMyAlerts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loadingAlerts = false);
        return;
      }

      final data = await supabase
          .from('sos_alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _myAlerts = List<Map<String, dynamic>>.from(data);
          _loadingAlerts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAlerts = false);
      }
    }
  }

  Future<void> _fetchNearbyServices() async {
    if (_latitude == null || _longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable location'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _loadingServices = true);
    }

    try {
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

      for (var service in services) {
        service.distance = _calculateDistance(
          _latitude!,
          _longitude!,
          service.lat,
          service.lng,
        );
      }

      services.sort((a, b) => a.distance.compareTo(b.distance));

      if (mounted) {
        setState(() {
          _nearbyServices = services;
          _loadingServices = false;
        });

        _showServicesBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingServices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading services'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
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
                  const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 20,
                  ),
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
                      'No services found',
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
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    try {
      final uri = Uri(scheme: 'geo', path: '$lat,$lng');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _sendSOS() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login first'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Getting location...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
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

      if (mounted) {
        setState(() {
          _isSending = false;
          _alertSent = true;
        });
        _successController.forward(from: 0);
      }

      await _loadMyAlerts();

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        await _fetchNearbyServices();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send SOS'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
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
      debugPrint('Error: $e');
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
                      'Use only in genuine emergency situations.',
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
                      'Getting location...',
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
                      'Location ready ✓',
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontSize: 12,
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
              'GPS coordinates sent with alert',
              Colors.blueAccent,
              isDark,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.local_hospital_outlined,
              'Find Services',
              'Locate nearby hospitals and ambulances',
              Colors.redAccent,
              isDark,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.people_outline_rounded,
              'Alert Broadcast',
              'Nearby users will be notified',
              Colors.orange,
              isDark,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._myAlerts.map(
                (alert) => _buildAlertItem(alert, textPrimary, textSecondary),
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
          'Help is on the way',
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
    Color textPrimary,
    Color textSecondary,
  ) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);

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
    Color textPrimary,
    Color textSecondary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);

    final status = alert['status'] as String? ?? 'active';
    final isActive = status == 'active';

    Color statusColor = isActive ? Colors.redAccent : Colors.grey;

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
            child: Text(
              'SOS Alert - $status',
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: () => _cancelAlert(alert['id']),
              child: Icon(Icons.close_rounded, color: textSecondary, size: 16),
            ),
        ],
      ),
    );
  }
}

class EmergencyService {
  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  double distance;

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
