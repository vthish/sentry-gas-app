// --- lib/connect_hub_page.dart (UPDATED with "Radar Scan" UI) ---

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart'; // For Background
import 'dart:ui'; // For ImageFilter.blur
import 'page_transitions.dart';
import 'custom_toast.dart';
import 'auth_gate.dart';
import 'hub_service.dart';

class ConnectHubPage extends StatefulWidget {
  const ConnectHubPage({super.key});

  @override
  State<ConnectHubPage> createState() => _ConnectHubPageState();
}

class _ConnectHubPageState extends State<ConnectHubPage> {
  final HubService _hubService = HubService();
  static const String TARGET_DEVICE_NAME = "sentry";

  // --- State Variables ---
  bool _permissionsGranted = false;
  String _statusText = "Plug in your Hub and place it nearby.";
  bool _isScanning = false;
  bool _isConnecting = false;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // --- Check permissions on load ---
  Future<void> _checkPermissions() async {
    var bleScanStatus = await Permission.bluetoothScan.status;
    var bleConnectStatus = await Permission.bluetoothConnect.status;
    var locationStatus = await Permission.location.status;

    if (bleScanStatus.isGranted &&
        bleConnectStatus.isGranted &&
        locationStatus.isGranted) {
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
          _statusText = "Plug in your Hub and place it nearby.";
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionsGranted = false;
          _statusText = "Bluetooth & Location permissions are required.";
        });
      }
    }
  }

  // --- Request Permissions ---
  Future<bool> _requestPermissions() async {
    if (_permissionsGranted) return true;

    setState(() {
      _statusText = "Requesting permissions...";
    });
    
    var bleScanPermission = await Permission.bluetoothScan.request();
    var bleConnectPermission = await Permission.bluetoothConnect.request();
    var locationPermission = await Permission.location.request();

    if (bleScanPermission.isGranted &&
        bleConnectPermission.isGranted &&
        locationPermission.isGranted) {
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
          _statusText = "Ready to scan. Press 'Find My Hub'.";
        });
        showCustomToast(context, "Permissions granted!");
      }
      return true;
    } else {
      if (mounted) {
        setState(() {
          _permissionsGranted = false;
          _statusText = "Bluetooth & Location access are required.";
        });
      }
      return false;
    }
  }

  // --- Start Scan ---
  Future<void> _startScan() async {
    // First, ensure permissions are granted
    bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      showCustomToast(context, "Please grant permissions to scan.", isError: true);
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      setState(() => _statusText = "Please turn on Bluetooth.");
      return;
    }

    setState(() {
      _isScanning = true;
      _statusText = "Scanning for '$TARGET_DEVICE_NAME' Hubs...";
      _scanResults = [];
    });

    try {
      FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results
                .where((r) => r.device.platformName
                    .toLowerCase()
                    .contains(TARGET_DEVICE_NAME.toLowerCase()))
                .toList();
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();

      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusText = _scanResults.isEmpty
              ? "Hmm, I can't find any Hubs. Try scanning again."
              : "Found Hub(s). Select your Hub from the list:";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusText = "Error scanning. Please try again.";
        });
      }
    }
  }

  // --- Connect to Device ---
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _statusText = "Connecting to ${device.platformName}...";
    });

    try {
      await device.connect(autoConnect: false).timeout(const Duration(seconds: 15));
      String? newHubId = await _hubService.linkBluetoothHubToUser(
          device.platformName.isEmpty ? "My Sentry Hub" : device.platformName,
          device.remoteId.toString());

      if (mounted && newHubId != null) {
        showCustomToast(
            context, "Successfully connected to ${device.platformName}");
        _navigateToAuthGate();
      } else if (mounted) {
        throw Exception("Failed to create Hub in Firestore");
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Connection failed: $e", isError: true);
        setState(() {
          _isConnecting = false;
          _statusText = "Failed to connect. Please try again.";
        });
      }
    }
  }

  // --- Skip for Demo Hub ---
  Future<void> _skipAndCreateDemoHub() async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _statusText = "Creating your Demo Hub...";
    });
    try {
      String? newHubId =
          await _hubService.createDemoHubForCurrentUser("Demo Hub");
      if (!mounted) return;
      if (newHubId != null) {
        showCustomToast(context, "Demo Hub Created Successfully!");
        _navigateToAuthGate();
      } else {
        throw Exception(
            "Failed to create Demo Hub. Check rules or connection.");
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Error: ${e.toString()}", isError: true);
        setState(() {
          _isConnecting = false;
          _statusText = "Failed to create Demo Hub. Please try again.";
        });
      }
    }
  }

  // --- Navigate to AuthGate ---
  void _navigateToAuthGate() {
    FlutterBluePlus.stopScan();
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }

  // --- Blue-Only Animated Background ---
  Widget _buildAnimatedBackground() {
    final tween1 = TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.blue.shade900,
          end: Colors.indigo.shade800,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.indigo.shade800,
          end: Colors.cyan.shade900,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.cyan.shade900,
          end: Colors.blue.shade900,
        ),
        weight: 1,
      ),
    ]);

    final tween2 = TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.teal.shade900,
          end: Colors.blue.shade800,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.blue.shade800,
          end: Colors.indigo.shade700,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.indigo.shade700,
          end: Colors.teal.shade900,
        ),
        weight: 1,
      ),
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
                    color1 ?? Colors.blue.shade900,
                    const Color(0xFF1A202C),
                    color2 ?? Colors.teal.shade900,
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

  // --- NEW: Radar Scan Animation ---
  Widget _buildRadarAnimation() {
    return SizedBox(
      height: 200, // Fixed height for the radar
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Icon
          Icon(
            Icons.settings_input_antenna,
            color: Colors.blue.shade300,
            size: 40,
          ),
          // Pulsing Waves
          Icon(Icons.circle, color: Colors.blue.withOpacity(0.5), size: 10)
              .animate(
                onPlay: (controller) => controller.repeat(),
                delay: 0.ms,
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(20, 20),
                duration: 2000.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 2000.ms),
          Icon(Icons.circle, color: Colors.blue.withOpacity(0.3), size: 10)
              .animate(
                onPlay: (controller) => controller.repeat(),
                delay: 1000.ms, // Staggered start
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(20, 20),
                duration: 2000.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 2000.ms),
        ],
      ),
    );
  }
  // --- End of Radar Animation ---

  // --- NEW: Scan Results List Widget ---
  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        var result = _scanResults[index];
        return Card(
          color: Colors.white.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          child: ListTile(
            title: Text(
                result.device.platformName.isEmpty
                    ? "Unknown Device"
                    : result.device.platformName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(result.device.remoteId.toString(),
                style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: _isConnecting ? null : () => _connectToDevice(result.device),
          ),
        );
      },
    );
  }
  // --- End of Results List ---

  // --- NEW: Glass Button Widget ---
  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue.withOpacity(0.2),
          side: BorderSide(color: Colors.blue.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
  // --- End of Glass Button ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: Stack(
        children: [
          // 1. The background
          _buildAnimatedBackground(),

          // 2. The content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                // --- The Main Glass Card ---
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      // --- Dynamic Content inside the card ---
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _buildDynamicContent(), // <-- NEW: Logic moved here
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // 3. The "Skip" button at the bottom
      bottomNavigationBar: Container(
        color: Colors.transparent, // Make it transparent
        padding: const EdgeInsets.all(24.0),
        child: TextButton(
          onPressed: _isConnecting ? null : _skipAndCreateDemoHub,
          child: Text(
            "Skip & create a Demo Hub",
            style: GoogleFonts.inter(
              color: Colors.white54,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: Helper to decide what to show inside the card ---
  Widget _buildDynamicContent() {
    // State 3: Connecting...
    if (_isConnecting) {
      return Column(
        key: const ValueKey('connecting'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 32),
          Text(
            _statusText,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ).animate().fadeIn();
    }
    
    // State 2: Scanning...
    if (_isScanning) {
      return Column(
        key: const ValueKey('scanning'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRadarAnimation(), // <-- The Radar
          Text(
            _statusText,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn();
    }
    
    // State 4: Scan Results are in
    if (_scanResults.isNotEmpty) {
      return Column(
        key: const ValueKey('results'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_connected, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            _statusText,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildResultsList(), // <-- The List
          const SizedBox(height: 16),
          // Button to scan again
          _buildGlassButton(
            onPressed: _startScan,
            child: Text(
              "SCAN AGAIN",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ).animate().fadeIn();
    }

    // State 1: Default / Get Ready
    return Column(
      key: const ValueKey('ready'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.power_settings_new_rounded,
            color: Colors.blue.shade300, size: 80),
        const SizedBox(height: 24),
        Text(
          "Let's Connect!",
          style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          _statusText,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildGlassButton(
          onPressed: _permissionsGranted ? _startScan : _requestPermissions,
          child: Text(
            _permissionsGranted ? "FIND MY HUB" : "GRANT PERMISSIONS",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

}