import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart'; 
import 'dart:ui'; 
import 'dart:convert';
import 'dart:async';
import 'dart:io'; 
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
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  bool _permissionsGranted = false;
  String _statusText = "Plug in your Hub and place it nearby.";
  bool _isScanning = false;
  bool _isConnecting = false;
  List<ScanResult> _scanResults = [];

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  StreamSubscription? _notifySubscription; 

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _notifySubscription?.cancel(); 
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    var bleScanStatus = await Permission.bluetoothScan.status;
    var bleConnectStatus = await Permission.bluetoothConnect.status;
    var locationStatus = await Permission.location.status;

    if (bleScanStatus.isGranted && bleConnectStatus.isGranted && locationStatus.isGranted) {
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

  Future<bool> _requestPermissions() async {
    if (_permissionsGranted) return true;
    setState(() => _statusText = "Requesting permissions...");
    
    var bleScanPermission = await Permission.bluetoothScan.request();
    var bleConnectPermission = await Permission.bluetoothConnect.request();
    var locationPermission = await Permission.location.request();

    if (bleScanPermission.isGranted && bleConnectPermission.isGranted && locationPermission.isGranted) {
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

  Future<void> _startScan() async {
    bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      showCustomToast(context, "Please grant permissions to scan.", isError: true);
      return;
    }

    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
       if (Platform.isAndroid) {
         try { await FlutterBluePlus.turnOn(); } catch (e) {
            showCustomToast(context, "Please turn on Bluetooth manually.", isError: true);
            return;
         }
       } else {
         showCustomToast(context, "Please turn on Bluetooth in Settings.", isError: true);
         return;
       }
    }

    setState(() {
      _isScanning = true;
      _statusText = "Scanning for '$TARGET_DEVICE_NAME' Hubs...";
      _scanResults = [];
    });

    try {
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results
                .where((r) => r.device.platformName.toLowerCase().contains(TARGET_DEVICE_NAME.toLowerCase()))
                .toList();
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      subscription.cancel();

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

  // --- CHANGED: Added State for Password Visibility inside Dialog ---
  void _showWifiDialog(BluetoothDevice device) {
    _ssidController.clear();
    _passwordController.clear();
    
    // Dialog එක ඇතුලේ password එක පේනවද නැද්ද කියලා බලන්න Variable එකක්
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8), 
      builder: (context) {
        // StatefulBuilder allows us to rebuild ONLY the dialog when clicking the eye icon
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_rounded, color: Colors.blue.shade300, size: 40),
                        const SizedBox(height: 16),
                        Text("Connect Hub to Wi-Fi",
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text("Enter your Wi-Fi details below.",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // SSID Input
                        _buildDialogTextField(
                          controller: _ssidController, 
                          label: "Wi-Fi Name (SSID)", 
                          icon: Icons.router
                        ),
                        const SizedBox(height: 16),
                        
                        // Password Input with Eye Icon Logic
                        _buildDialogTextField(
                          controller: _passwordController, 
                          label: "Password", 
                          icon: Icons.lock, 
                          isObscure: !isPasswordVisible, // Toggle visibility
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(foregroundColor: Colors.white60, padding: const EdgeInsets.symmetric(vertical: 16)),
                                child: Text("Cancel", style: GoogleFonts.inter(fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); 
                                    _connectAndConfigHub(device, _ssidController.text, _passwordController.text);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text("CONNECT", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Updated Helper to accept Suffix Icon ---
  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon, // New Parameter for the eye icon
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.blue.shade300),
        suffixIcon: suffixIcon, // Add the eye icon here
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade400)),
      ),
    );
  }

  // --- Connect Logic (12 Second Timeout) ---
  Future<void> _connectAndConfigHub(BluetoothDevice device, String ssid, String password) async {
    if (ssid.isEmpty) {
      showCustomToast(context, "Wi-Fi Name is required!", isError: true);
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusText = "Connecting to Hub...";
    });

    try {
      await device.connect(autoConnect: false).timeout(const Duration(seconds: 15));
      
      setState(() => _statusText = "Sending Wi-Fi Details...");

      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetChar;

      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == CHARACTERISTIC_UUID) {
              targetChar = char;
              break;
            }
          }
        }
      }

      if (targetChar == null) throw Exception("Hub service not found.");

      // Setup Listener
      await targetChar.setNotifyValue(true);
      Completer<bool> connectionCompleter = Completer<bool>();

      _notifySubscription = targetChar.lastValueStream.listen((value) async {
         String response = utf8.decode(value);
         if (response.contains("SUCCESS") && !connectionCompleter.isCompleted) {
            connectionCompleter.complete(true);
         } else if (response.contains("FAIL") && !connectionCompleter.isCompleted) {
            connectionCompleter.complete(false);
         }
      });

      // Send Data
      String dataToSend = "$ssid,$password";
      await targetChar.write(utf8.encode(dataToSend));
      
      setState(() => _statusText = "Verifying Credentials (Max 10s)...");

      // Timeout Reduced to 12s
      bool isSuccess = await connectionCompleter.future.timeout(const Duration(seconds: 12));
      
      _notifySubscription?.cancel(); 

      if (isSuccess) {
         setState(() => _statusText = "Connected! Finalizing...");
         await device.disconnect(); 

         String? newHubId = await _hubService.linkBluetoothHubToUser(
           device.platformName.isEmpty ? "My Sentry Hub" : device.platformName,
           device.remoteId.toString()
         );

         if (mounted && newHubId != null) {
           showCustomToast(context, "Hub Configured Successfully!");
           _navigateToAuthGate();
         }
      } else {
         throw Exception("Wrong Password or Failed.");
      }

    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Connection Failed. Check password and try again.", isError: true);
        setState(() {
          _isConnecting = false;
          _statusText = "Failed. Tap the Hub to try again.";
        });
        _notifySubscription?.cancel();
        try { await device.disconnect(); } catch (_) {}
      }
    }
  }

  void _navigateToAuthGate() {
    FlutterBluePlus.stopScan();
    Navigator.of(context).pushAndRemoveUntil(
      FadePageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }

  // --- Background ---
  Widget _buildAnimatedBackground() {
    return LoopAnimationBuilder<Color?>(
      tween: TweenSequence([
        TweenSequenceItem(tween: ColorTween(begin: Colors.blue.shade900, end: Colors.indigo.shade800), weight: 1),
        TweenSequenceItem(tween: ColorTween(begin: Colors.indigo.shade800, end: Colors.cyan.shade900), weight: 1),
        TweenSequenceItem(tween: ColorTween(begin: Colors.cyan.shade900, end: Colors.blue.shade900), weight: 1),
      ]),
      duration: const Duration(seconds: 20),
      builder: (context, color1, child) {
         return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1 ?? Colors.blue.shade900, const Color(0xFF1A202C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
         );
      },
    );
  }

  // --- Radar ---
  Widget _buildRadarAnimation() {
    return SizedBox(
      height: 200, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.settings_input_antenna, color: Colors.blue.shade300, size: 40),
          Icon(Icons.circle, color: Colors.blue.withOpacity(0.5), size: 10)
              .animate(onPlay: (controller) => controller.repeat(), delay: 0.ms)
              .scale(begin: const Offset(1, 1), end: const Offset(20, 20), duration: 2000.ms, curve: Curves.easeOut)
              .fadeOut(duration: 2000.ms),
        ],
      ),
    );
  }

  // --- Results List ---
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.2))),
          child: ListTile(
            title: Text(result.device.platformName.isEmpty ? "Unknown Device" : result.device.platformName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: _isConnecting ? null : () => _showWifiDialog(result.device),
          ),
        );
      },
    );
  }

  Widget _buildGlassButton({required VoidCallback? onPressed, required Widget child}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue.withOpacity(0.2),
          side: BorderSide(color: Colors.blue.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _buildDynamicContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent() {
    if (_isConnecting) {
      return Column(
        key: const ValueKey('connecting'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 32),
          Text(_statusText, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 32),
        ],
      ).animate().fadeIn();
    }
    
    if (_isScanning) {
      return Column(
        key: const ValueKey('scanning'),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRadarAnimation(),
          Text(_statusText, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
        ],
      ).animate().fadeIn();
    }
    
    if (_scanResults.isNotEmpty) {
      return Column(
        key: const ValueKey('results'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_connected, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(_statusText, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildResultsList(),
          const SizedBox(height: 16),
          _buildGlassButton(
            onPressed: _startScan,
            child: Text("SCAN AGAIN", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ).animate().fadeIn();
    }

    return Column(
      key: const ValueKey('ready'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.power_settings_new_rounded, color: Colors.blue.shade300, size: 80),
        const SizedBox(height: 24),
        Text("Let's Connect!", style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(_statusText, style: GoogleFonts.inter(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        _buildGlassButton(
          onPressed: _permissionsGranted ? _startScan : _requestPermissions,
          child: Text(_permissionsGranted ? "FIND MY HUB" : "GRANT PERMISSIONS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    ).animate().fadeIn();
  }
}