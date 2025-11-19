// --- lib/notification_alerts_page.dart (UPDATED: All toggles on Firestore) ---

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_toast.dart'; // Make sure this file exists in your project
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⭐️ NOTE: This page now assumes the user is logged in.
// We removed SharedPreferences logic for simplicity.

class NotificationAlertsPage extends StatefulWidget {
  const NotificationAlertsPage({super.key});

  @override
  State<NotificationAlertsPage> createState() => _NotificationAlertsPageState();
}

class _NotificationAlertsPageState extends State<NotificationAlertsPage> {
  // ⭐️ REMOVED ALL LOCAL STATE bools (_gasLeakAlert, _lowGasWarning, etc.)
  // StreamBuilder will manage all state from Firestore.

  // Get the current User ID
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // ⭐️ REMOVED initState and _loadSettings
  // StreamBuilder handles all loading.

  // ⭐️ UPDATED: _saveSetting function
  // This is now a simple, generic function to update any field in Firestore.
  Future<void> _saveSetting(String firestoreKey, bool value) async {
    if (userId == null) {
      if (mounted) {
        showCustomToast(context, "LOGIN ERROR: You must be logged in.",
            isError: true);
      }
      return;
    }
    try {
      print("Saving '$firestoreKey: $value' to Firestore...");
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        firestoreKey: value,
      }, SetOptions(merge: true));

      print("--- ✅ FIRESTORE SAVE SUCCESSFUL ---");
      if (mounted) showCustomToast(context, "Setting saved!", isError: false);
    } catch (e) {
      print("--- 🛑 FIRESTORE SAVE FAILED 🛑 ---");
      print(e.toString());
      if (mounted) {
        showCustomToast(context, "Failed to save: ${e.toString()}",
            isError: true);
      }
    }
  }

  // --- (Animated Background and Glassmorphism functions are UNCHANGED) ---
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
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    );
  }
  // --- (End of unchanged functions) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // ... (AppBar is unchanged) ...
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Notification Alerts",
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            // ⭐️ UPDATED: The whole list is now inside ONE StreamBuilder
            child: StreamBuilder<DocumentSnapshot>(
              // Listen to the user's document in real-time
              stream: (userId != null)
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .snapshots()
                  : null, // If user is not logged in, stream is null
              builder: (context, snapshot) {
                
                // Show a loading indicator while waiting
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                // Handle errors or if user is not logged in
                if (!snapshot.hasData || (snapshot.hasError) || userId == null) {
                  return const Center(
                    child: Text(
                      "Please log in to see settings.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                
                // If we have data, get the settings map
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

                // Get the real-time value for each toggle
                // We use '?? true' as a fallback if the field doesn't exist yet
                final bool gasLeakAlertValue = data['gasLeakAlerts'] ?? true;
                final bool lowGasWarningValue = data['lowGasWarningAlerts'] ?? true;
                final bool hubOfflineAlertValue = data['hubOfflineAlerts'] ?? true;

                // Build the list using the real-time values
                return SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      _buildAlertItem(
                        icon: Icons.error_outline,
                        iconColor: Colors.red.shade300,
                        title: "Gas Leak Alerts",
                        value: gasLeakAlertValue, // Value comes from stream
                        onChanged: (newValue) {
                          // Save using the FIRESTORE KEY
                          _saveSetting('gasLeakAlerts', newValue);
                        },
                        delay: 100.ms,
                      ),
                      const SizedBox(height: 12),
                      _buildAlertItem(
                        icon: Icons.opacity_outlined,
                        iconColor: Colors.orange.shade300,
                        title: "Low Gas Warning (20%)",
                        value: lowGasWarningValue, // Value comes from stream
                        onChanged: (newValue) {
                          // Save using the FIRESTORE KEY
                          _saveSetting('lowGasWarningAlerts', newValue);
                        },
                        delay: 200.ms,
                      ),
                      const SizedBox(height: 12),
                      _buildAlertItem(
                        icon: Icons.wifi_off_outlined,
                        iconColor: Colors.grey.shade400,
                        title: "Hub is Offline",
                        value: hubOfflineAlertValue, // Value comes from stream
                        onChanged: (newValue) {
                          // Save using the FIRESTORE KEY
                          _saveSetting('hubOfflineAlerts', newValue);
                        },
                        delay: 300.ms,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- _buildAlertItem is UNCHANGED ---
  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Duration delay,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _glassmorphismCardDecoration(), // Glass effect
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green, // Keep green for 'ON'
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            inactiveThumbColor: Colors.white54,
            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay)
        .slideY(
          begin: 0.3,
          duration: 500.ms,
          delay: delay,
          curve: Curves.easeOutCubic,
        );
  }
}