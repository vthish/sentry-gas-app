// --- lib/connect_hub_page.dart (FINAL FIXED - Added material.dart) ---

import 'package:flutter/material.dart'; // <-- **** මෙන්න අමතක වුණු, අත්‍යවශ්‍යම import එක! ****
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _isScanning = false;
  bool _isConnecting = false;
  String _scanStatus = "Let's find your new Sentry Gas Hub.";
  List<ScanResult> _scanResults = [];

  Future<void> _startScan() async {
    var bleScanPermission = await Permission.bluetoothScan.request();
    var bleConnectPermission = await Permission.bluetoothConnect.request();
    var locationPermission = await Permission.location.request();
    if (bleScanPermission.isGranted && bleConnectPermission.isGranted && locationPermission.isGranted) {
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        setState(() {
          _isScanning = true;
          _scanStatus = "Scanning for '$TARGET_DEVICE_NAME' Hubs...";
          _scanResults = [];
        });
        try {
          FlutterBluePlus.scanResults.listen((results) {
            if (mounted) {
              setState(() {
                _scanResults = results.where((r) =>
                    r.device.platformName.toLowerCase().contains(TARGET_DEVICE_NAME.toLowerCase())
                ).toList();
              });
            }
          });
          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
          await Future.delayed(const Duration(seconds: 5));
          await FlutterBluePlus.stopScan();
          if (mounted) {
            setState(() {
              _isScanning = false;
              _scanStatus = _scanResults.isEmpty
                  ? "Hmm, I can't find any '$TARGET_DEVICE_NAME' Hubs. Try again."
                  : "Found Hub(s). Select your Hub:";
            });
          }
        } catch (e) {
             if (mounted) {
                setState(() {
                    _isScanning = false;
                    _scanStatus = "Error scanning. Please try again.";
                });
             }
        }
      } else {
        setState(() => _scanStatus = "Please turn on Bluetooth.");
      }
    } else {
      setState(() => _scanStatus = "Bluetooth & Location access required.");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
        _isConnecting = true;
        _scanStatus = "Connecting to ${device.platformName}...";
    });
    try {
      await device.connect(autoConnect: false).timeout(const Duration(seconds: 15));
      String? newHubId = await _hubService.linkBluetoothHubToUser(
        device.platformName.isEmpty ? "My Sentry Hub" : device.platformName,
        device.remoteId.toString()
      );
      if (mounted && newHubId != null) {
         showCustomToast(context, "Successfully connected to ${device.platformName}");
         _navigateToAuthGate();
      } else if (mounted) {
        throw Exception("Failed to create Hub in Firestore");
      }
    } catch (e) {
      if (mounted) {
          setState(() {
              _isConnecting = false;
              _scanStatus = "Failed to connect. Please try again.";
          });
          showCustomToast(context, "Connection failed: $e", isError: true);
      }
    }
  }

  // "Skip" button එක click කළ විට
  Future<void> _skipAndCreateDemoHub() async {
    // දැනටමත් connection process එකක් යනවා නම් නැවත click කිරීම වැළැක්වීම
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _scanStatus = "Creating your Demo Hub...";
    });
    try {
      String? newHubId = await _hubService.createDemoHubForCurrentUser("Demo Hub");

      if (!mounted) return; // Widget එක dispose වී ඇත්නම් නවතින්න

      if (newHubId != null) {
        // සාර්ථකයි
        showCustomToast(context, "Demo Hub Created Successfully!");
        _navigateToAuthGate();
      } else {
        // අසාර්ථකයි (null ලැබුණොත්)
        throw Exception("Failed to create Demo Hub in Firestore. Check rules or connection.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _scanStatus = "Failed. Please try again.";
        });
        // Error එක toast එකක් මගින් පෙන්වීම
        showCustomToast(context, "Error: ${e.toString()}", isError: true);
        print("Skip Error: $e"); // Debugging සඳහා Terminal එකේ print කිරීම
      }
    }
  }

  // AuthGate එකට යොමු කිරීම
  void _navigateToAuthGate() {
    FlutterBluePlus.stopScan();
    // pushReplacement වෙනුවට pushAndRemoveUntil භාවිතා කිරීම වඩාත් ආරක්ෂිතයි,
    // එවිට ආපසු ඒමට (back) නොහැකි වේ.
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Let's Connect!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
              ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 40),
              Icon(Icons.sensors, color: Colors.blue.shade300, size: 120)
                  .animate().fade(delay: 300.ms).scale(),
              const SizedBox(height: 40),
              Text(
                _scanStatus,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 18, color: Colors.white70)
              ).animate().fade(delay: 400.ms),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isScanning || _isConnecting
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _startScan,
                            child: const Text("FIND MY HUB"),
                          ),
                          TextButton(
                            onPressed: _skipAndCreateDemoHub, // <-- Skip button
                            child: Text(
                              "Skip connection & create a Demo Hub",
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                    var result = _scanResults[index];
                    return Card(
                      color: const Color(0xFF2D3748),
                      child: ListTile(
                        title: Text(result.device.platformName.isEmpty ? "Unknown Device" : result.device.platformName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(color: Colors.white70)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white),
                        onTap: _isConnecting ? null : () => _connectToDevice(result.device),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 600.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}