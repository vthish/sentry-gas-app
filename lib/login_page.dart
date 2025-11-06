// --- lib/login_page.dart (FINAL FIXED - 'random' error + Pop-ups) ---

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'package:simple_animations/simple_animations.dart'; 
import 'dart:math'; // <-- Animated Dots සඳහා
import 'page_transitions.dart'; 
import 'connect_hub_page.dart';
import 'gas_cylinder_icon.dart'; 
import 'custom_toast.dart'; // <-- අපේ අලුත් Liquid Glass Pop-up

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = "";
  bool _isOtpSent = false;
  bool _isLoading = false;

  // --- Functions (Send OTP, Verify, Sign In) ---
  
  Future<void> _sendOtp() async {
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
       _showErrorToast("Please enter a phone number."); // <-- Pop-up
       return;
    }
    if (!phoneNumber.startsWith('+94')) {
      phoneNumber = '+94$phoneNumber';
    }
    setState(() => _isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signIn(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showErrorToast("Failed to send code: ${e.message}"); // <-- Pop-up
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showErrorToast(e.toString()); // <-- Pop-up
    }
  }

  Future<void> _verifyOtp() async {
     if (_otpController.text.trim().length < 6) {
      _showErrorToast("Please enter the 6-digit code."); // <-- Pop-up
      return;
    }
    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await _signIn(credential);
    } catch (e) {
      _showErrorToast("Invalid OTP. Please try again."); // <-- Pop-up
    }
  }

  Future<void> _signIn(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      if (mounted) {
        // **** SnackBar එක වෙනුවට අලුත් Pop-up ****
        showCustomToast(context, "Welcome Home! Login Successful."); 
        
        Navigator.of(context).pushReplacement(
          FadePageRoute(builder: (context) => const ConnectHubPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorToast("Failed to sign in: ${e.message}"); // <-- Pop-up
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // **** SnackBar function එක Pop-up function එකෙන් replace කිරීම ****
  void _showErrorToast(String message) {
    if (mounted) {
      showCustomToast(context, message, isError: true); // <-- Pop-up
      setState(() => _isLoading = false);
    }
  }
  // --- End of Functions ---


  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      body: Stack( 
        children: [
          const BackgroundParticles(particleCount: 30), 
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    GasCylinderIcon(
                      size: 80,
                      color: Colors.blue.shade400,
                    ).animate().fade(delay: 200.ms).scale(duration: 400.ms),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome to Sentry Gas",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2, duration: 400.ms),

                    const SizedBox(height: 10),
                    Text(
                      "Easy Sign-in using your Phone",
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
                    ).animate().fade(delay: 400.ms),
                    
                    const SizedBox(height: 50),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _isOtpSent
                          ? _buildOtpForm(defaultPinTheme)
                          : _buildPhoneForm(),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phoneForm'),
      children: [
        Text(
          "Enter Your Phone Number",
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                "+94",
                style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
              ),
            ),
            hintText: "71 123 4567",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("GET ACCESS CODE"),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildOtpForm(PinTheme defaultPinTheme) {
    return Column(
      key: const ValueKey('otpForm'),
      children: [
        Text(
          "Enter 6-Digit Code",
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Pinput(
          controller: _otpController,
          length: 6,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: Colors.blue.shade400),
            ),
          ),
          onCompleted: (pin) => _verifyOtp(),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("VERIFY & SIGN IN"),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isOtpSent = false;
              _isLoading = false;
            });
          },
          child: const Text(
            "Use a different phone number?",
            style: TextStyle(color: Colors.white70),
          ),
        )
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

// --- BACKGROUND ANIMATED DOTS WIDGET (NEW & FIXED) ---

class BackgroundParticles extends StatelessWidget {
  final int particleCount;
  const BackgroundParticles({super.key, this.particleCount = 30});

  @override
  Widget build(BuildContext context) {
    return LoopAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(value, particleCount),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final int particleCount;
  final List<Particle> particles;
  
  // **** මෙන්න දෝෂය නිවැරදි කළ තැන! ****
  // 'random' object එක instance field එකක් විදිහට නැතුව, constructor එකේදී හදනවා
  ParticlePainter(this.animationValue, this.particleCount)
      : particles = List.generate(particleCount, (index) => Particle(Random())); // <-- 'random' මෙතනදී create කිරීම

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.15);

    for (var particle in particles) {
      final offset = particle.move(animationValue, size);
      canvas.drawCircle(offset, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

class Particle {
  final Random random;
  final double size;
  final double speed;
  final Offset direction;
  final Offset initialPosition;

  Particle(this.random) // <-- 'random' object එක constructor එකෙන් inject කිරීම
      : size = random.nextDouble() * 2.0 + 1.0, 
        speed = random.nextDouble() * 20.0 + 10.0, 
        direction = Offset(
          random.nextDouble() * 2.0 - 1.0, 
          random.nextDouble() * 2.0 - 1.0, 
        ).normalize(),
        initialPosition = Offset(
          random.nextDouble(),
          random.nextDouble(),
        );

  Offset move(double animationValue, Size size) {
    final progress = (animationValue * speed) % 1.0;
    
    final dx = (initialPosition.dx * size.width + direction.dx * progress * 100) % size.width;
    final dy = (initialPosition.dy * size.height + direction.dy * progress * 100) % size.height;

    return Offset(
      dx < 0 ? dx + size.width : dx,
      dy < 0 ? dy + size.height : dy,
    );
  }
}

// Offset extension එකක්
extension on Offset {
  Offset normalize() {
    final d = distance;
    if (d == 0) return Offset.zero;
    return Offset(dx / d, dy / d);
  }
}