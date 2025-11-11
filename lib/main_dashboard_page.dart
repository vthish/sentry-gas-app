// --- lib/main_dashboard_page.dart (UPDATED WITH NOTIFICATION LOGIC) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_gas_app/settings_page.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To read settings
import 'page_transitions.dart';
import 'custom_toast.dart';
import 'auth_gate.dart';
import 'notification_service.dart'; // <-- Import the new notification service

class MainDashboardPage extends StatefulWidget {
  final List<String> hubIds; // This is a List

  const MainDashboardPage({super.key, required this.hubIds});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.hubIds.length,
        onPageChanged: (index) {
          setState(() => _currentPageIndex = index);
        },
        itemBuilder: (context, index) {
          // Create a separate dashboard for each Hub ID
          return SingleHubDashboard(
            hubId: widget.hubIds[index],
            // Only show indicator dots if there is more than one hub
            showPageIndicator: widget.hubIds.length > 1,
            currentPage: _currentPageIndex,
            totalPages: widget.hubIds.length,
          );
        },
      ),
    );
  }
}

// --- WIDGET FOR A SINGLE HUB ---
class SingleHubDashboard extends StatefulWidget {
  final String hubId;
  final bool showPageIndicator;
  final int currentPage;
  final int totalPages;

  const SingleHubDashboard({
    super.key,
    required this.hubId,
    required this.showPageIndicator,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<SingleHubDashboard> createState() => _SingleHubDashboardState();
}

class _SingleHubDashboardState extends State<SingleHubDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- NEW STATE VARIABLES FOR NOTIFICATIONS ---
  // To check if the "Low Gas Warning" setting is enabled
  bool _lowGasWarningEnabled = true; // Default to true
  // To prevent sending multiple notifications for the same event
  bool _lowGasNotificationSent = false;

  @override
  void initState() {
    super.initState();
    // When the dashboard loads, request notification permission
    _requestNotificationPermission();
    // Also load the user's saved notification preferences
    _loadNotificationSettings();
  }

  // Request permission from the user (for Android 13+)
  Future<void> _requestNotificationPermission() async {
    await NotificationService.requestPermissions();
  }

  // Load settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        // We only care about the low gas warning here
        _lowGasWarningEnabled = prefs.getBool('lowGasWarning') ?? true;
      });
    }
  }

  // --- NEW: LOGIC TO CHECK GAS LEVEL AND SEND NOTIFICATION ---
  void _checkGasLevelAndNotify(double gasLevel) {
    // Check if gas is low, the setting is enabled, AND we haven't sent a notification yet
    if (gasLevel < 20 && _lowGasWarningEnabled && !_lowGasNotificationSent) {
      NotificationService.showNotification(
        id: 1, // Unique ID for this notification type
        title: "Low Gas Warning",
        body: "Your gas level is at ${gasLevel.toInt()}%. Time to order a refill!",
      );
      // Set flag to true to prevent spamming notifications
      if (mounted) {
        setState(() => _lowGasNotificationSent = true);
      }
    }
    // If gas level goes above 20 (e.g., refill), reset the flag
    else if (gasLevel > 20 && _lowGasNotificationSent) {
      if (mounted) {
        setState(() => _lowGasNotificationSent = false);
      }
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      FadePageRoute(builder: (context) => SettingsPage(currentHubId: widget.hubId)),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          FadePageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
        showCustomToast(context, "Logged out successfully.");
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Error logging out: $e", isError: true);
      }
    }
  }

  Future<void> _updateValveStatus(bool newValue) async {
    if (widget.hubId == "DEMO_HUB") {
      showCustomToast(context, "Valve control disabled in Demo Mode", isError: true);
      return;
    }
    try {
      await _firestore.collection('hubs').doc(widget.hubId).update({'valveOn': newValue});
    } catch (e) {
      showCustomToast(context, "Error updating valve: $e", isError: true);
    }
  }

  Future<void> _recalibrateMeter() async {
    if (widget.hubId == "DEMO_HUB") {
      showCustomToast(context, "Recalibrate disabled in Demo Mode", isError: true);
      return;
    }
    try {
      await _firestore.collection('hubs').doc(widget.hubId).update({'gasLevel': 100.0});
      showCustomToast(context, "Meter reset to 100%");
    } catch (e) {
      showCustomToast(context, "Error resetting meter: $e", isError: true);
    }
  }

  void _showRecalibrateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3748),
        title: Text("New Cylinder?", style: GoogleFonts.inter(color: Colors.white)),
        content: Text("Did you just connect a full gas cylinder? This will reset the meter to 100%.", style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(
            onPressed: () {
              _recalibrateMeter();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Yes, Reset Meter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDemoMode = (widget.hubId == "DEMO_HUB");

    if (isDemoMode) {
      // --- Handle Demo Mode ---
      double demoGasLevel = 72.0; // Example
      _checkGasLevelAndNotify(demoGasLevel); // Check demo level too
      return _buildDashboardUI(
        hubName: "Demo Hub",
        gasLevel: demoGasLevel,
        isValveOn: true,
        statusMessage: "Everything is OK (Demo)",
        isDemoMode: true,
      );
    }

    // --- Handle Real Data from Firestore ---
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('hubs').doc(widget.hubId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        Map<String, dynamic> hubData = snapshot.data!.data() as Map<String, dynamic>;
        
        double gasLevel = hubData['gasLevel']?.toDouble() ?? 0.0;
        
        // --- NEW: Check gas level every time data updates ---
        _checkGasLevelAndNotify(gasLevel);

        return _buildDashboardUI(
          hubName: hubData['hubName'] ?? "My Hub",
          gasLevel: gasLevel,
          isValveOn: hubData['valveOn'] ?? false,
          statusMessage: hubData['statusMessage'] ?? "Status Unknown",
          isDemoMode: false,
        );
      },
    );
  }

  // --- Main UI Widget (No changes here) ---
  Widget _buildDashboardUI({
    required String hubName,
    required double gasLevel,
    required bool isValveOn,
    required String statusMessage,
    required bool isDemoMode,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          onPressed: _navigateToSettings,
        ),
        title: Column(
          children: [
            Text(hubName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)).animate().fade(),
            if (widget.showPageIndicator)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.totalPages, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.currentPage == index ? Colors.blue : Colors.white24,
                    ),
                  );
                }),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              SizedBox(
                height: 300,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0, maximum: 100, startAngle: 180, endAngle: 0,
                      showLabels: false, showTicks: false,
                      axisLineStyle: AxisLineStyle(thickness: 0.2, cornerStyle: CornerStyle.bothCurve, color: Colors.white.withOpacity(0.1), thicknessUnit: GaugeSizeUnit.factor),
                      pointers: <GaugePointer>[
                        RangePointer(value: gasLevel, cornerStyle: CornerStyle.bothCurve, width: 0.2, sizeUnit: GaugeSizeUnit.factor, gradient: SweepGradient(colors: <Color>[gasLevel < 20 ? Colors.red.shade700 : (gasLevel < 50 ? Colors.orange.shade700 : Colors.green.shade700), gasLevel < 20 ? Colors.red : (gasLevel < 50 ? Colors.orange : Colors.green)], stops: const <double>[0.0, 1.0]), enableAnimation: true, animationDuration: 1000),
                        MarkerPointer(value: gasLevel, markerType: MarkerType.circle, color: Colors.white, markerWidth: 20, markerHeight: 20, enableAnimation: true, animationDuration: 1000)
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(positionFactor: 0.1, angle: 90, widget: Column(mainAxisSize: MainAxisSize.min, children: [Text("${gasLevel.toInt()}%", style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)), Text("Gas Level", style: GoogleFonts.inter(fontSize: 16, color: Colors.white54))]))
                      ],
                    ),
                  ],
                ),
              ).animate().scale(delay: 200.ms, duration: 600.ms),
              const Spacer(flex: 1),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.green.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 10), Text(statusMessage, style: GoogleFonts.inter(color: Colors.green.shade300, fontWeight: FontWeight.w600, fontSize: 16))]),
              ).animate().fade(delay: 500.ms).slideY(begin: 0.5),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF2D3748), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Gas Valve", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(isValveOn ? "Currently ON" : "Currently OFF", style: GoogleFonts.inter(color: isValveOn ? Colors.green.shade300 : Colors.red.shade300, fontSize: 14))]),
                    Transform.scale(scale: 1.2, child: Switch(value: isValveOn, onChanged: (newValue) => isDemoMode ? showCustomToast(context, "Disabled in Demo Mode", isError: true) : _updateValveStatus(newValue), activeColor: Colors.green, inactiveTrackColor: Colors.red.shade900.withOpacity(0.5), inactiveThumbColor: Colors.red.shade300)),
                  ]),
              ).animate().fade(delay: 600.ms).slideY(begin: 0.5),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: isDemoMode ? () => showCustomToast(context, "Disabled in Demo Mode", isError: true) : _showRecalibrateDialog, icon: const Icon(Icons.refresh, color: Colors.blue), label: Text("Connected a New Cylinder?", style: GoogleFonts.inter(color: Colors.blue.shade300, fontSize: 16, fontWeight: FontWeight.w600)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.blue.shade900), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))).animate().fade(delay: 700.ms).slideY(begin: 0.5),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: TextButton(onPressed: _navigateToSettings, child: Text("Settings & More", style: GoogleFonts.inter(color: Colors.white70, fontSize: 16, decoration: TextDecoration.underline)))).animate().fade(delay: 800.ms),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}