import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_gas_app/settings_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page_transitions.dart';
import 'custom_toast.dart';
import 'auth_gate.dart';
import 'notification_service.dart';
import 'hub_settings_page.dart';
import 'dart:ui'; 
import 'package:simple_animations/simple_animations.dart'; 
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'dart:math'; 

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
    _initAndSaveFcmToken();
  }

  Future<void> _initAndSaveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userDocRef.set({
        'fcmToken': fcmToken,
        'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving FCM token: $e");
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
  DateTime? _lastLowGasNotificationTime;
  late final String _lastLowGasTimeKey;

  @override
  void initState() {
    super.initState();
    _lastLowGasTimeKey = 'lastLowGasTime_${widget.hubId}';
    _requestNotificationPermission();
    _loadNotificationSettings();
  }

  Future<void> _requestNotificationPermission() async {
    await NotificationService.requestPermissions();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeMillis = prefs.getInt(_lastLowGasTimeKey);

    if (mounted) {
      setState(() {
        _lowGasWarningEnabled = prefs.getBool('lowGasWarning') ?? true;

        if (lastTimeMillis != null) {
          _lastLowGasNotificationTime =
              DateTime.fromMillisecondsSinceEpoch(lastTimeMillis);
        }
      });
    }
  }

  void _checkGasLevelAndNotify(double gasLevel) async {
    final now = DateTime.now();
    final bool canSend = _lastLowGasNotificationTime == null ||
        now.difference(_lastLowGasNotificationTime!).inMinutes >= 60;

    if (gasLevel < 20 && _lowGasWarningEnabled && canSend) {
      NotificationService.showNotification(
        id: 1,
        title: "Low Gas Warning",
        body: "Your gas level is at ${gasLevel.toInt()}%. Time to order a refill!",
      );

      if (mounted) {
        setState(() {
          _lastLowGasNotificationTime = now;
        });
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt(_lastLowGasTimeKey, now.millisecondsSinceEpoch);
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

      final prefs = await SharedPreferences.getInstance();
      prefs.remove(_lastLowGasTimeKey);
      if (mounted) setState(() => _lastLowGasNotificationTime = null);
    } catch (e) {
      showCustomToast(context, "Error resetting meter: $e", isError: true);
    }
  }

  void _showRecalibrateDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.75),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: Colors.white.withOpacity(0.7), width: 1.5),
          ),
          title: Text("New Cylinder?",
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
              "Did you just connect a full gas cylinder? This will reset the meter to 100%.",
              style: GoogleFonts.inter(color: Colors.white70)),
          actionsPadding:
              const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                elevation: 0,
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.25)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text("No",
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            ElevatedButton(
              onPressed: () {
                _recalibrateMeter();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Yes, Reset Meter",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final tween1 = TweenSequence([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A1931), end: const Color(0xFF182848)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF182848), end: const Color(0xFF004A7C)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF004A7C), end: const Color(0xFF0A1931)),
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

  Path _buildGasCylinderPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double neckWidth = w * 0.35;
    final double neckHeight = h * 0.1;
    final double bodyRadius = w * 0.25;
    final double topBodyRadius = w * 0.15;
    final double bodyTop = neckHeight + (h * 0.05);

    final Path bodyPath = Path();
    bodyPath.addRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, bodyTop, w, h - bodyTop),
        topLeft: Radius.circular(topBodyRadius),
        topRight: Radius.circular(topBodyRadius),
        bottomLeft: Radius.circular(bodyRadius),
        bottomRight: Radius.circular(bodyRadius),
      ),
    );

    final Path neckPath = Path();
    neckPath.addRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH((w - neckWidth) / 2, 0, neckWidth, bodyTop),
        topLeft: Radius.circular(neckWidth / 4),
        topRight: Radius.circular(neckWidth / 4),
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero,
      ),
    );

    final Path combinedPath = Path.from(bodyPath);
    combinedPath.addPath(neckPath, Offset.zero);

    return combinedPath;
  }

  @override
  Widget build(BuildContext context) {
    bool isDemoMode = (widget.hubId == "DEMO_HUB");

    if (isDemoMode) {
      double demoGasLevel = 17.0;
      _checkGasLevelAndNotify(demoGasLevel);
      return _buildDashboardUI(
        gasLevel: demoGasLevel,
        isValveOn: false,
        isGasLeak: false, // Demo mode safe
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
        // --- NEW: Read gasLeak status from Firestore ---
        bool isGasLeak = hubData['gasLeak'] ?? false; 
        bool isValveOn = hubData['valveOn'] ?? false;

        _checkGasLevelAndNotify(gasLevel);

        return _buildDashboardUI(
          gasLevel: gasLevel,
          isValveOn: isValveOn,
          isGasLeak: isGasLeak, // Pass leak status to UI
          isDemoMode: false,
        );
      },
    );
  }

  // --- UPDATED LOGIC: Prioritize Gas Leak Status ---
  Map<String, dynamic> _getStatusData(double gasLevel, bool isGasLeak) {
    // Check 1: Is there a Gas Leak?
    if (isGasLeak) {
      return {
        'text': "CRITICAL: Gas Leak Detected!",
        'color': Colors.red.shade600, // Strong Red
        'icon': Icons.dangerous_rounded,
      };
    } 
    // Check 2: Low Gas?
    else if (gasLevel <= 20) {
      return {
        'text': "Status: Gas is getting low",
        'color': Colors.orange.shade400,
        'icon': Icons.warning_amber_rounded,
      };
    } else if (gasLevel <= 50) {
      return {
        'text': "Status: Everything is OK",
        'color': Colors.blue.shade300, // Changed to Blue/Greenish
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
    required bool isGasLeak, // Received here
    required bool isDemoMode,
  }) {
    // Pass isGasLeak to status generator
    final statusData = _getStatusData(gasLevel, isGasLeak);
    final statusText = statusData['text'] as String;
    final statusColor = statusData['color'] as Color;
    final statusIcon = statusData['icon'] as IconData;

    // Determine liquid color (Red if leak or low)
    final Color liquidColor = (isGasLeak || gasLevel < 20)
        ? Colors.red.shade400
        : (gasLevel < 50 ? Colors.orange.shade400 : Colors.green.shade400);

    return Stack(
      children: [
        _buildAnimatedBackground(),

        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // --- Liquid Cylinder ---
                SizedBox(
                  height: 300,
                  width: 220,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final Path cylinderPath =
                          _buildGasCylinderPath(constraints.biggest);

                      return Stack(
                        children: [
                          ClipPath(
                            clipper: _CylinderClipper(cylinderPath),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ClipPath(
                            clipper: _CylinderClipper(cylinderPath),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: (100 - gasLevel) / 100,
                              child: _VaporAnimation(
                                size: constraints.biggest,
                                startFromPercent: gasLevel / 100,
                              ),
                            ),
                          ),
                          LiquidCustomProgressIndicator(
                            value: gasLevel / 100,
                            valueColor: AlwaysStoppedAnimation(liquidColor),
                            backgroundColor: Colors.transparent,
                            direction: Axis.vertical,
                            shapePath: cylinderPath,
                            center: Text(
                              "${gasLevel.toInt()}%",
                              style: GoogleFonts.inter(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        blurRadius: 10,
                                        color: Colors.black.withOpacity(0.5))
                                  ]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ).animate().scale(delay: 200.ms, duration: 600.ms),
                
                const Spacer(flex: 1),

                // --- Glass Status Box (Colors change based on Leak) ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: _glassStatusDecoration(statusColor),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 10),
                    Expanded( // Added Expanded to handle long leak text
                      child: Text(statusText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    )
                  ]),
                ).animate().fade(delay: 500.ms).slideY(begin: 0.5),
                const SizedBox(height: 40),

                // --- Glassmorphism Card for Valve ---
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
                                      isGasLeak
                                          ? "LOCKED (Leak Detected)" // Show Locked Text
                                          : (isValveOn
                                              ? "Currently ON"
                                              : "Currently OFF"),
                                      style: GoogleFonts.inter(
                                          color: isGasLeak
                                              ? Colors.red.shade300 // Red text if locked
                                              : (isValveOn
                                                  ? Colors.green.shade300
                                                  : Colors.red.shade300),
                                          fontSize: 14))
                                ]),
                            Transform.scale(
                                scale: 1.2,
                                child: Switch(
                                    value: isValveOn,
                                    // --- UPDATED SWITCH LOGIC ---
                                    onChanged: (newValue) {
                                      if (isDemoMode) {
                                        showCustomToast(context, "Disabled in Demo Mode", isError: true);
                                      } else if (isGasLeak) {
                                        // LOCK THE VALVE: Show Error Toast
                                        showCustomToast(
                                          context, 
                                          "Valve Locked: Leak Detected! Fix leak to reset.", 
                                          isError: true
                                        );
                                      } else {
                                        // Normal Operation
                                        _updateValveStatus(newValue);
                                      }
                                    },
                                    activeColor: isGasLeak ? Colors.grey : Colors.green, // Grey out if leak
                                    inactiveTrackColor: Colors.red.shade900.withOpacity(0.5),
                                    inactiveThumbColor: isGasLeak ? Colors.grey : Colors.red.shade300)),
                          ]),
                    ),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.5),
                const SizedBox(height: 20),

                // --- Glass Button for Recalibrate ---
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
                        : () => _showRecalibrateDialog(),
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

// --- PARTICLES ANIMATION (No Changes needed here, but kept for completeness) ---
class _VaporAnimation extends StatefulWidget {
  final Size size;
  final double startFromPercent;

  const _VaporAnimation({
    required this.size,
    required this.startFromPercent,
  });

  @override
  State<_VaporAnimation> createState() => _VaporAnimationState();
}

class _VaporPuffModel {
  late Offset position;
  late double size;
  late double initialSize;
  late double maxOpacity;
  late double life; 
  late double wobbleFrequency;
  late double initialHorizontalOffset;
  late double lifeSpanFactor;

  _VaporPuffModel(Size bounds, Random random) {
    life = 0.0;
    initialSize = random.nextDouble() * 20 + 30; 
    size = initialSize;
    maxOpacity = random.nextDouble() * 0.1 + 0.1; 
    wobbleFrequency = random.nextDouble() * 2 + 2; 
    initialHorizontalOffset = random.nextDouble() * bounds.width;
    position = Offset(initialHorizontalOffset, bounds.height); 
    lifeSpanFactor = random.nextDouble() * 0.4 + 0.8; 
  }

  void update(double deltaTime, Size bounds) {
    life += (deltaTime / 4) * lifeSpanFactor;
    position = position.translate(0, -20 * deltaTime); 
    final wobble = sin(life * wobbleFrequency * pi) * bounds.width * 0.1;
    position = Offset(initialHorizontalOffset + wobble, position.dy);
    size = initialSize + (life * 30);
  }

  bool isDead() => life >= 1.0;

  double getOpacity() {
    if (life < 0.1) {
      return (life / 0.1) * maxOpacity; 
    }
    if (life > 0.8) {
      return ((1.0 - life) / 0.2) * maxOpacity; 
    }
    return maxOpacity;
  }
}

class _VaporAnimationState extends State<_VaporAnimation>
    with SingleTickerProviderStateMixin { 
  late AnimationController _controller;
  final List<_VaporPuffModel> particles = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), 
    );
    _controller.addListener(_updateParticles);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    setState(() {
      particles.removeWhere((p) => p.isDead());
      const double deltaTime = 0.016; 
      for (var particle in particles) {
        particle.update(deltaTime, widget.size);
      }
      if (random.nextDouble() < 0.03) { 
        particles.add(_VaporPuffModel(widget.size, random));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VaporPainter(particles),
      size: widget.size,
    );
  }
}

class _VaporPainter extends CustomPainter {
  final List<_VaporPuffModel> particles;
  final Paint particlePaint = Paint();
  
  _VaporPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final opacity = particle.getOpacity();
      if (opacity <= 0) continue;

      final gradient = RadialGradient(
        colors: [
          Colors.white.withOpacity(opacity * 0.5), 
          Colors.white.withOpacity(0.0), 
        ],
      );

      particlePaint.shader = gradient.createShader(
        Rect.fromCircle(center: particle.position, radius: particle.size / 2)
      );

      canvas.drawCircle(particle.position, particle.size / 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CylinderClipper extends CustomClipper<Path> {
  final Path path;
  
  _CylinderClipper(this.path);

  @override
  Path getClip(Size size) {
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}