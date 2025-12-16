

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'page_transitions.dart';
import 'auth_gate.dart'; 
import 'custom_toast.dart';



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


  
  Future<void> _sendOtp() async {
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
        _showErrorToast("Please enter a phone number.");
        return;
    }
    if (phoneNumber.length == 9 && !phoneNumber.startsWith('+')) {
      phoneNumber = '+94${phoneNumber.substring(0)}';
    } 
    else if (phoneNumber.length == 10 && phoneNumber.startsWith('0')) {
      phoneNumber = '+94${phoneNumber.substring(1)}';
    } 
    else if (!phoneNumber.startsWith('+94')) {
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
          _showErrorToast("Failed to send code: ${e.message}");
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
      _showErrorToast(e.toString());
    }
  }

  Future<void> _verifyOtp() async {
     if (_otpController.text.trim().length < 6) {
      _showErrorToast("Please enter the 6-digit code.");
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
      _showErrorToast("Invalid OTP. Please try again.");
    }
  }

  Future<void> _signIn(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      if (mounted) {
        showCustomToast(context, "Welcome Home! Login Successful."); 
        Navigator.of(context).pushReplacement(
          FadePageRoute(builder: (context) => const AuthGate()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorToast("Failed to sign in: ${e.message}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorToast(String message) {
    if (mounted) {
      showCustomToast(context, message, isError: true);
      setState(() => _isLoading = false);
    }
  }




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



  @override
  Widget build(BuildContext context) {
    final glassPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Match TextField
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.blue.shade900.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          )
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.blue.shade300, Colors.cyan.shade300],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.propane_tank_outlined,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fade(delay: 200.ms).scale(duration: 400.ms),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome Home",
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
                    
                    const SizedBox(height: 40),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: _isOtpSent
                                ? _buildOtpForm(glassPinTheme)
                                : _buildPhoneForm(),
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Enter Phone Number",
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 10, 15),
              child: Text(
                "+94",
                style: GoogleFonts.inter(fontSize: 18, color: Colors.white70),
              ),
            ),

            hintText: "71 123 4567",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
        ),
        const SizedBox(height: 24),
        

        SizedBox(
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
            onPressed: _isLoading ? null : _sendOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                : Text(
                    "GET ACCESS CODE",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }


  Widget _buildOtpForm(PinTheme glassPinTheme) {
    return Column(
      key: const ValueKey('otpForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter 6-Digit Code",
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Pinput(
          controller: _otpController,
          length: 6,
          defaultPinTheme: glassPinTheme,
          focusedPinTheme: glassPinTheme.copyWith(
            decoration: glassPinTheme.decoration!.copyWith(
              border: Border.all(color: Colors.blue.shade400, width: 2),
            ),
          ),
          onCompleted: (pin) => _verifyOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                : Text(
                    "VERIFY & SIGN IN",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isOtpSent = false;
                _isLoading = false;
              });
            },
            child: const Text(
              "Use a different phone number?",
              style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
            ),
          ),
        )
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}
