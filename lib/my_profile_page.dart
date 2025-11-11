// --- lib/my_profile_page.dart (UPDATED with "Liquid Crystal" UI) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_toast.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        if (mounted) {
          setState(() {
            _nameController.text =
                (userDoc.data() as Map<String, dynamic>)['displayName'] ?? "";
          });
        }
      }
    } catch (e) {
      // Error silently
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'displayName': _nameController.text.trim(),
        'phoneNumber': user!.phoneNumber,
      }, SetOptions(merge: true));

      if (mounted) {
        showCustomToast(context, "Profile updated successfully!");
        Navigator.pop(context); // Go back to Settings page
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Failed to save profile: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW: "Dark Blue" Animated Background ---
  Widget _buildAnimatedBackground() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- UPDATED: Transparent background ---
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("My Profile",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- UPDATED: Use Stack for background ---
      body: Stack(
        children: [
          _buildAnimatedBackground(), // <-- The animation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Your Name",
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14))
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  // --- UPDATED: Glassmorphism TextField ---
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      hintStyle: GoogleFonts.inter(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1), // Glass fill
                      // Crystal border
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideX(begin: 0.1, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  Text("Phone Number",
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14))
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  // --- UPDATED: Glassmorphism Container ---
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient( // Glass gradient
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all( // Crystal border
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user?.phoneNumber ?? "Unknown",
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideX(begin: 0.1, curve: Curves.easeOut),

                  const Spacer(),

                  // --- UPDATED: Glass Button ---
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
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text("SAVE CHANGES",
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}