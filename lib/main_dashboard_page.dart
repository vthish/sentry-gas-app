// --- lib/main_dashboard_page.dart (UPDATED with "Advanced Cylinder" Path & "Dark Blue" BG) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_gas_app/settings_page.dart';
// REMOVED: import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page_transitions.dart';
import 'custom_toast.dart';
import 'auth_gate.dart';
import 'notification_service.dart';
import 'hub_settings_page.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

class MainDashboardPage extends StatefulWidget {
  final List<String> hubIds;
  const MainDashboardPage({super.key, required this.hubIds});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentPageIndex = 0;
  Stream<DocumentSnapshot>? _currentHubStream;
  String _currentHubName = "Loading...";

  @override
  void initState() {
    super.initState();
    if (widget.hubIds.isNotEmpty) {
      _listenToHubStream(widget.hubIds[0]);
    }
  }

  void _listenToHubStream(String hubId) {
    if (hubId == "DEMO_HUB") {
      setState(() {
        _currentHubStream = null;
        _currentHubName = "Demo Hub";
      });
    } else {
      setState(() {
        _currentHubStream =
            _firestore.collection('hubs').doc(hubId).snapshots();
      });
    }
  }

  // --- Navigation Functions (No Change) ---
  void _navigateToSettings() {
    String currentHubId = widget.hubIds[_currentPageIndex];
    Navigator.of(context).push(
      FadePageRoute(
          builder: (context) => SettingsPage(currentHubId: currentHubId)),
    );
  }

  void _navigateToHubSettings() {
    String currentHubId = widget.hubIds[_currentPageIndex];
    Navigator.of(context).push(
      FadePageRoute(
          builder: (context) => HubSettingsPage(currentHubId: currentHubId)),
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
  // --- End of Navigation Functions ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          tooltip: 'Settings & More',
          onPressed: _navigateToSettings,
        ),
        title: InkWell(
          onTap: _navigateToHubSettings,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _currentHubStream == null
                      ? Text(
                          _currentHubName,
                          key: ValueKey<String>(_currentHubName),
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        )
                      : StreamBuilder<DocumentSnapshot>(
                          stream: _currentHubStream,
                          builder: (context, snapshot) {
                            String hubName = "Loading...";
                            if (snapshot.hasData && snapshot.data!.exists) {
                              hubName = (snapshot.data!.data()
                                      as Map<String, dynamic>)['hubName'] ??
                                  'My Hub';
                            }
                            return Text(
                              hubName,
                              key: ValueKey<String>(hubName),
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                ),
                if (widget.hubIds.length > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.hubIds.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPageIndex == index
                              ? Colors.blue
                              : Colors.white24,
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.hubIds.length,
        onPageChanged: (index) {
          setState(() => _currentPageIndex = index);
          _listenToHubStream(widget.hubIds[index]);
        },
        itemBuilder: (context, index) {
          return SingleHubDashboard(
            key: ValueKey<String>(widget.hubIds[index]),
            hubId: widget.hubIds[index],
          );
        },
      ),
    );
  }
}

// --- WIDGET FOR A SINGLE HUB ---
class SingleHubDashboard extends StatefulWidget {
  final String hubId;

  const SingleHubDashboard({
    super.key,
    required this.hubId,
  });

  @override
  State<SingleHubDashboard> createState() => _SingleHubDashboardState();
}

class _SingleHubDashboardState extends State<SingleHubDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _lowGasWarningEnabled = true;
  bool _lowGasNotificationSent = false;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _loadNotificationSettings();
  }

  Future<void> _requestNotificationPermission() async {
    await NotificationService.requestPermissions();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lowGasWarningEnabled = prefs.getBool('lowGasWarning') ?? true;
      });
    }
  }

  void _checkGasLevelAndNotify(double gasLevel) {
    if (gasLevel < 20 && _lowGasWarningEnabled && !_lowGasNotificationSent) {
      NotificationService.showNotification(
        id: 1,
        title: "Low Gas Warning",
        body:
            "Your gas level is at ${gasLevel.toInt()}%. Time to order a refill!",
      );
      if (mounted) {
        setState(() => _lowGasNotificationSent = true);
      }
    } else if (gasLevel > 20 && _lowGasNotificationSent) {
      if (mounted) {
        setState(() => _lowGasNotificationSent = false);
      }
    }
  }

  Future<void> _updateValveStatus(bool newValue) async {
    if (widget.hubId == "DEMO_HUB") {
      showCustomToast(context, "Valve control disabled in Demo Mode",
          isError: true);
      return;
    }
    try {
      await _firestore
          .collection('hubs')
          .doc(widget.hubId)
          .update({'valveOn': newValue});
    } catch (e) {
      showCustomToast(context, "Error updating valve: $e", isError: true);
    }
  }

  Future<void> _recalibrateMeter() async {
    if (widget.hubId == "DEMO_HUB") {
      showCustomToast(context, "Recalibrate disabled in Demo Mode",
          isError: true);
      return;
    }
    try {
      await _firestore
          .collection('hubs')
          .doc(widget.hubId)
          .update({'gasLevel': 100.0});
      showCustomToast(context, "Meter reset to 100%");
    } catch (e) {
      showCustomToast(context, "Error resetting meter: $e", isError: true);
    }
  }

  void _showRecalibrateDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Text("New Cylinder?",
              style: GoogleFonts.inter(color: Colors.white)),
          content: Text(
              "Did you just connect a full gas cylinder? This will reset the meter to 100%.",
              style: GoogleFonts.inter(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("No", style: TextStyle(color: Colors.white70))),
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
      ),
    );
  }

  // --- UPDATED: "Dark Blue" Animated Background ---
  Widget _buildAnimatedBackground() {
    // Dark Blue, Midnight, Deep Navy color palette
    final tween1 = TweenSequence([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A1931), end: const Color(0xFF182848)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF182848), end: const Color(0xFF00334E)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF00334E), end: const Color(0xFF0A1931)),
          weight: 1),
    ]);
    final tween2 = TweenSequence([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A2342), end: const Color(0xFF182848)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF182848), end: const Color(0xFF0A1931)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A1931), end: const Color(0xFF0A2342)),
          weight: 1),
    ]);
    return LoopAnimationBuilder<Color?>(
      tween: tween1,
      duration: const Duration(seconds: 20),
      builder: (context, color1, child) {
        return LoopAnimationBuilder<Color?>(
          tween: tween2,
          duration: const Duration(seconds: 25),
          builder: (context, color2, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color1 ?? const Color(0xFF0A1931),
                    const Color(0xFF1A202C),
                    color2 ?? const Color(0xFF0A2342),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        );
      },
    );
  }
  // --- End of Animated Background ---

  // --- Glassmorphism Decoration Helpers (No Change) ---
  BoxDecoration _glassmorphismCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
    );
  }

  BoxDecoration _glassStatusDecoration(Color statusColor) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          statusColor.withOpacity(0.25),
          statusColor.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: statusColor.withOpacity(0.3)),
    );
  }
  // --- End of Helpers ---

  // --- UPDATED: New "Decent & Advance" Cylinder Path ---
  Path _buildGasCylinderPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Proportions
    final double bodyHeight = h * 0.82;
    final double bodyWidth = w;
    final double bodyRadius = w * 0.15; // More curve
    
    final double neckHeight = h * 0.18;
    final double neckWidth = w * 0.4;
    final double neckRadius = neckWidth * 0.5; // Top dome radius
    
    final double shoulderWidth = (bodyWidth - neckWidth) / 2;

    final Path path = Path();
    
    // Start at bottom-left
    path.moveTo(0, h - bodyRadius);

    // Bottom-left curve
    path.quadraticBezierTo(0, h, bodyRadius, h);
    
    // Bottom line
    path.lineTo(w - bodyRadius, h);
    
    // Bottom-right curve
    path.quadraticBezierTo(w, h, w, h - bodyRadius);
    
    // Right side
    path.lineTo(w, neckHeight);

    // Top-right shoulder (curves inwards)
    path.quadraticBezierTo(w, neckHeight * 0.5, w - shoulderWidth, neckHeight * 0.5);

    // Top-right neck base
    path.lineTo(w - shoulderWidth, neckRadius);

    // Top dome/arc
    path.arcToPoint(
      Offset(shoulderWidth, neckRadius),
      radius: Radius.circular(neckRadius),
      clockwise: false,
    );

    // Top-left neck base
    path.lineTo(shoulderWidth, neckHeight * 0.5);
    
    // Top-left shoulder
    path.quadraticBezierTo(0, neckHeight * 0.5, 0, neckHeight);

    // Left side
    path.close(); // Closes back to start
    
    return path;
  }
  // --- End of Path Helper ---


  @override
  Widget build(BuildContext context) {
    bool isDemoMode = (widget.hubId == "DEMO_HUB");

    if (isDemoMode) {
      double demoGasLevel = 72.0;
      _checkGasLevelAndNotify(demoGasLevel);
      return _buildDashboardUI(
        gasLevel: demoGasLevel,
        isValveOn: true,
        isDemoMode: true,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('hubs').doc(widget.hubId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Stack(
            children: [
              _buildAnimatedBackground(),
              const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ],
          );
        }
        Map<String, dynamic> hubData =
            snapshot.data!.data() as Map<String, dynamic>;

        double gasLevel = hubData['gasLevel']?.toDouble() ?? 0.0;

        _checkGasLevelAndNotify(gasLevel);

        return _buildDashboardUI(
          gasLevel: gasLevel,
          isValveOn: hubData['valveOn'] ?? false,
          isDemoMode: false,
        );
      },
    );
  }

  Map<String, dynamic> _getStatusData(double gasLevel) {
    if (gasLevel <= 20) {
      return {
        'text': "Status: Gas is getting low",
        'color': Colors.red.shade400,
        'icon': Icons.warning_amber_rounded,
      };
    } else if (gasLevel <= 50) {
      return {
        'text': "Status: Everything is OK",
        'color': Colors.orange.shade400,
        'icon': Icons.check_circle_outline_rounded,
      };
    } else {
      return {
        'text': "Status: Everything is OK",
        'color': Colors.green.shade400,
        'icon': Icons.check_circle_rounded,
      };
    }
  }

  Widget _buildDashboardUI({
    required double gasLevel,
    required bool isValveOn,
    required bool isDemoMode,
  }) {
    final statusData = _getStatusData(gasLevel);
    final statusText = statusData['text'] as String;
    final statusColor = statusData['color'] as Color;
    final statusIcon = statusData['icon'] as IconData;

    final Color liquidColor = gasLevel < 20
        ? Colors.red.shade400
        : (gasLevel < 50 ? Colors.orange.shade400 : Colors.green.shade400);

    return Stack(
      children: [
        _buildAnimatedBackground(), // <-- The new Dark Blue animation
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const Spacer(flex: 1),
                
                // --- UPDATED: Liquid Cylinder using the NEW Path ---
                SizedBox(
                  height: 300, 
                  width: 220,  // Made it slightly narrower for a better look
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Create the path using the constraints
                      final Path cylinderPath = _buildGasCylinderPath(constraints.biggest);

                      return LiquidCustomProgressIndicator(
                        value: gasLevel / 100, // 0.0 to 1.0
                        valueColor: AlwaysStoppedAnimation(liquidColor),
                        backgroundColor: Colors.white.withOpacity(0.15),
                        direction: Axis.vertical,
                        shapePath: cylinderPath, // <-- Use our NEW custom path
                        center: Text(
                          "${gasLevel.toInt()}%",
                          style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              // Add shadow to text to make it pop
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.5))
                              ]
                            ),
                        ),
                      );
                    },
                  ),
                ).animate().scale(delay: 200.ms, duration: 600.ms),
                // --- End of Replacement ---

                const Spacer(flex: 1),

                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: _glassStatusDecoration(statusColor),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 10),
                    Text(statusText,
                        style: GoogleFonts.inter(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16))
                  ]),
                ).animate().fade(delay: 500.ms).slideY(begin: 0.5),
                const SizedBox(height: 40),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _glassmorphismCardDecoration(),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Gas Valve",
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                      isValveOn
                                          ? "Currently ON"
                                          : "Currently OFF",
                                      style: GoogleFonts.inter(
                                          color: isValveOn
                                              ? Colors.green.shade300
                                              : Colors.red.shade300,
                                          fontSize: 14))
                                ]),
                            Transform.scale(
                                scale: 1.2,
                                child: Switch(
                                    value: isValveOn,
                                    onChanged: (newValue) => isDemoMode
                                        ? showCustomToast(
                                            context, "Disabled in Demo Mode",
                                            isError: true)
                                        : _updateValveStatus(newValue),
                                    activeColor: Colors.green,
                                    inactiveTrackColor:
                                        Colors.red.shade900.withOpacity(0.5),
                                    inactiveThumbColor: Colors.red.shade300)),
                          ]),
                    ),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.5),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      side: BorderSide(color: Colors.blue.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isDemoMode
                        ? () => showCustomToast(context, "Disabled in Demo Mode",
                            isError: true)
                        : _showRecalibrateDialog,
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    label: Text("Connected a New Cylinder?",
                        style: GoogleFonts.inter(
                            color: Colors.blue.shade300,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ).animate().fade(delay: 700.ms).slideY(begin: 0.5),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}