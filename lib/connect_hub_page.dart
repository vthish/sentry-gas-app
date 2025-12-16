import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:ui';
import 'dart:async';
import 'page_transitions.dart';
import 'custom_toast.dart';
import 'auth_gate.dart';
import 'hub_service.dart';

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderRadius = 10,
    this.borderLength = 20,
    this.borderWidth = 10,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect, textDirection: textDirection), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    double cutSize = cutOutSize;
    path.addRect(rect);
    double centerX = rect.center.dx;
    double centerY = rect.center.dy;
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(centerX, centerY), width: cutSize, height: cutSize),
        Radius.circular(borderRadius)));
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    double cutSize = cutOutSize;
    double centerX = rect.center.dx;
    double centerY = rect.center.dy;
    Rect cutOutRect = Rect.fromCenter(
        center: Offset(centerX, centerY), width: cutSize, height: cutSize);

    Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);

    Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    double cornerLength = borderLength;
    canvas.drawLine(cutOutRect.topLeft,
        cutOutRect.topLeft + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(cutOutRect.topLeft,
        cutOutRect.topLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(cutOutRect.topRight,
        cutOutRect.topRight + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(cutOutRect.topRight,
        cutOutRect.topRight - Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(cutOutRect.bottomLeft,
        cutOutRect.bottomLeft - Offset(0, cornerLength), borderPaint);
    canvas.drawLine(cutOutRect.bottomLeft,
        cutOutRect.bottomLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(cutOutRect.bottomRight,
        cutOutRect.bottomRight - Offset(0, cornerLength), borderPaint);
    canvas.drawLine(cutOutRect.bottomRight,
        cutOutRect.bottomRight - Offset(cornerLength, 0), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderRadius: borderRadius,
      borderLength: borderLength,
      borderWidth: borderWidth,
      cutOutSize: cutOutSize,
    );
  }
}

class ConnectHubPage extends StatefulWidget {
  const ConnectHubPage({super.key});

  @override
  State<ConnectHubPage> createState() => _ConnectHubPageState();
}

class _ConnectHubPageState extends State<ConnectHubPage>
    with WidgetsBindingObserver {
  final HubService _hubService = HubService();

  static const String ESP_IP_ADDRESS = "192.168.4.1";

  bool _permissionsGranted = false;
  String _statusText = "Make sure you have Internet access to verify Hub.";
  bool _isCameraActive = false;
  bool _isConnecting = false;
  bool _isValidating = false;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _subscription = controller.barcodes.listen(_handleBarcode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_isCameraActive) _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    controller.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isGranted) {
      if (mounted) setState(() => _permissionsGranted = true);
    } else {
      if (mounted) setState(() => _permissionsGranted = false);
    }
  }

  Future<void> _requestPermissions() async {
    var cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
          _statusText = "Camera Ready. Press 'Scan QR Code'.";
        });
        showCustomToast(context, "Camera permission granted!");
        _startCamera();
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionsGranted = false;
          _statusText = "Camera permission is required to scan QR.";
        });
      }
    }
  }

  void _startCamera() {
    setState(() {
      _isCameraActive = true;
      _statusText = "Point your camera at the Hub's QR Code.";
    });
    controller.start();
  }

  void _stopCamera() {
    setState(() {
      _isCameraActive = false;
    });
    controller.stop();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (!_isCameraActive || _isValidating) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        String scannedCode = barcode.rawValue!;

        _stopCamera();
        setState(() {
          _isValidating = true;
          _statusText = "Verifying Hub ID online...";
        });

        try {
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('valid_hubs')
              .doc(scannedCode)
              .get();

          if (doc.exists) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            bool isLinked = data['isLinked'] ?? false;

            if (isLinked) {
              if (mounted) {
                showCustomToast(
                    context, "This Hub is already linked to another user!",
                    isError: true);
                setState(() {
                  _isValidating = false;
                  _statusText = "Invalid Hub. Already in use.";
                });
              }
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) _startCamera();
            } else {
              if (mounted) {
                showCustomToast(context, "Hub Verified! Configure Wi-Fi.");
                setState(() {
                  _isValidating = false;
                });
                _showWifiDialog(scannedCode);
              }
            }
          } else {
            if (mounted) {
              showCustomToast(context, "Invalid QR Code. Hub not recognized.",
                  isError: true);
              setState(() {
                _isValidating = false;
                _statusText = "Invalid QR Code.";
              });
            }
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) _startCamera();
          }
        } catch (e) {
          if (mounted) {
            print("Validation Error: $e");
            showCustomToast(
                context, "Verification Failed. Check Internet Connection.",
                isError: true);
            setState(() {
              _isValidating = false;
              _statusText = "Network Error. Check Internet.";
            });
          }
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _startCamera();
        }
        break;
      }
    }
  }

  Future<void> _connectAndConfigHub(
      String ssid, String password, String validHubId) async {
    if (ssid.isEmpty) {
      showCustomToast(context, "Wi-Fi Name is required!", isError: true);
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusText = "Sending config to ESP8266...";
    });

    try {
      var url = Uri.parse("http://$ESP_IP_ADDRESS/config");
      var response = await http.post(
        url,
        body: {
          'ssid': ssid,
          'password': password,
          'user_id': FirebaseAuth.instance.currentUser?.uid ?? "UNKNOWN"
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _statusText =
              "Config Sent!\nPLEASE TURN ON MOBILE DATA (INTERNET) TO FINISH.";
        });

        try {
          await _hubService.linkBluetoothHubToUser("Sentry Hub", validHubId);

          await FirebaseFirestore.instance
              .collection('valid_hubs')
              .doc(validHubId)
              .update({
            'isLinked': true,
            'linkedBy': FirebaseAuth.instance.currentUser?.uid,
            'linkedAt': FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection('hubs')
              .doc(validHubId)
              .set({
            'qrcode': validHubId,
            'ownerId': FirebaseAuth.instance.currentUser?.uid,
            'valveOn': false,
            'statusMessage': 'Online',
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (mounted) {
            showCustomToast(context, "Hub Linked Successfully!");
            await Future.delayed(const Duration(seconds: 1));
            _navigateToAuthGate();
          }
        } catch (e) {
          print("Linking Error (Waiting for internet?): $e");

          if (mounted) {
            showCustomToast(context, "Hub Configured. Check Dashboard later.",
                isError: true);
            _navigateToAuthGate();
          }
        }
      } else {
        throw Exception("Hub returned error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        print(e);
        showCustomToast(
            context, "Failed to send. Are you connected to 'Sentry-Setup' Wi-Fi?",
            isError: true);
        setState(() {
          _isConnecting = false;
          _statusText = "Connection Error. Connect to 'Sentry-Setup' Wi-Fi.";
        });
      }
    }
  }

  void _showWifiDialog(String deviceId) {
    _ssidController.clear();
    _passwordController.clear();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
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
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_tethering,
                              color: Colors.blue.shade300, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            "Configure Hub Wi-Fi",
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text("Hub ID: $deviceId",
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 12)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.5))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "IMPORTANT:\n1. Minimize App.\n2. Connect Phone to 'Sentry-Setup' Wi-Fi.\n3. Come back & click SEND.",
                                    style: GoogleFonts.inter(
                                        color: Colors.orange.shade100,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                              controller: _ssidController,
                              label: "Home Wi-Fi Name (SSID)",
                              icon: Icons.router),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock,
                            isObscure: !isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white70),
                              onPressed: () => setDialogState(
                                  () => isPasswordVisible = !isPasswordVisible),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _startCamera();
                                      },
                                      child: Text("Cancel",
                                          style: GoogleFonts.inter(
                                              color: Colors.white60)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);

                                  _connectAndConfigHub(_ssidController.text,
                                      _passwordController.text, deviceId);
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600),
                                child: Text("SEND TO HUB",
                                    style:
                                        GoogleFonts.inter(color: Colors.white)),
                              )),
                            ],
                          )
                        ],
                      ),
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

  Widget _buildDialogTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isObscure = false,
      Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.blue.shade300),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade400)),
      ),
    );
  }

  void _navigateToAuthGate() {
    Navigator.of(context).pushAndRemoveUntil(
        FadePageRoute(builder: (context) => const AuthGate()),
        (route) => false);
  }

  Widget _buildAnimatedBackground() {
    return LoopAnimationBuilder<Color?>(
      tween: TweenSequence([
        TweenSequenceItem(
            tween: ColorTween(
                begin: Colors.blue.shade900, end: Colors.purple.shade900),
            weight: 1),
        TweenSequenceItem(
            tween: ColorTween(
                begin: Colors.purple.shade900, end: Colors.blue.shade900),
            weight: 1),
      ]),
      duration: const Duration(seconds: 20),
      builder: (context, color1, child) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            color1 ?? Colors.blue.shade900,
            const Color(0xFF1A202C)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          if (_isCameraActive && !_isValidating)
            Positioned.fill(
              child: Stack(
                children: [
                  MobileScanner(controller: controller),
                  Container(
                    decoration: ShapeDecoration(
                      shape: QrScannerOverlayShape(
                        borderColor: Colors.blue,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Center(
              child: (_isCameraActive || _isValidating)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isValidating)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 50),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            _isValidating
                                ? "Checking Database..."
                                : "Scan Sentry Gas QR Code",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: _stopCamera,
                          child: const Text("Cancel Scan",
                              style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05)
                              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5),
                            ),
                            child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: _buildDynamicContent()),
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
            Text(_statusText,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
          ]).animate().fadeIn();
    }
    return Column(
        key: const ValueKey('ready'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner_rounded,
              color: Colors.blue.shade300, size: 80),
          const SizedBox(height: 24),
          Text("Setup Sentry Hub",
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
              "1. Scan QR (Turn on Data).\n2. Switch to Hub WiFi.\n3. Send Config.",
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    side: BorderSide(color: Colors.blue.shade400),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed:
                    _permissionsGranted ? _startCamera : _requestPermissions,
                child: Text(
                    _permissionsGranted ? "SCAN QR CODE" : "ALLOW CAMERA",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              )),
        ]).animate().fadeIn();
  }
}