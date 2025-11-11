// --- lib/notification_alerts_page.dart (UPDATED with "Liquid Crystal" UI) ---

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_toast.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background

class NotificationAlertsPage extends StatefulWidget {
  const NotificationAlertsPage({super.key});

  @override
  State<NotificationAlertsPage> createState() => _NotificationAlertsPageState();
}

class _NotificationAlertsPageState extends State<NotificationAlertsPage> {
  bool _gasLeakAlert = true;
  bool _lowGasWarning = true;
  bool _hubOfflineAlert = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _gasLeakAlert = prefs.getBool('gasLeakAlert') ?? true;
          _lowGasWarning = prefs.getBool('lowGasWarning') ?? true;
          _hubOfflineAlert = prefs.getBool('hubOfflineAlert') ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // On error, still load with default values
        setState(() => _isLoading = false);
        showCustomToast(context, "Note: Using default settings (Couldn't load saved ones)", isError: true);
      }
    }
  }

  // Save setting to SharedPreferences
  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Failed to save setting. Please try again.", isError: true);
      }
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

  // --- NEW: Glassmorphism Decoration Helper ---
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
  // --- End of Helper ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- UPDATED: Use transparent background ---
      backgroundColor: Colors.transparent,
      appBar: AppBar(
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
      // --- UPDATED: Use Stack for background ---
      body: Stack(
        children: [
          _buildAnimatedBackground(), // <-- The animation

          // --- UPDATED: Add BackdropFilter for frosted glass effect ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        // --- UPDATED: Using new _buildAlertItem ---
                        _buildAlertItem(
                          icon: Icons.error_outline,
                          iconColor: Colors.red.shade300,
                          title: "Gas Leak Alerts",
                          value: _gasLeakAlert,
                          onChanged: (newValue) {
                            setState(() => _gasLeakAlert = newValue);
                            _saveSetting('gasLeakAlert', newValue);
                          },
                          delay: 100.ms,
                        ),
                        const SizedBox(height: 12), // Replaced Divider
                        _buildAlertItem(
                          icon: Icons.opacity_outlined,
                          iconColor: Colors.orange.shade300,
                          title: "Low Gas Warning (20%)",
                          value: _lowGasWarning,
                          onChanged: (newValue) {
                            setState(() => _lowGasWarning = newValue);
                            _saveSetting('lowGasWarning', newValue);
                          },
                          delay: 200.ms,
                        ),
                        const SizedBox(height: 12), // Replaced Divider
                        _buildAlertItem(
                          icon: Icons.wifi_off_outlined,
                          iconColor: Colors.grey.shade400,
                          title: "Hub is Offline",
                          value: _hubOfflineAlert,
                          onChanged: (newValue) {
                            setState(() => _hubOfflineAlert = newValue);
                            _saveSetting('hubOfflineAlert', newValue);
                          },
                          delay: 300.ms,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Rebuilt as a "Glassmorphism" Card ---
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
    // --- UPDATED: Smoother Staggered Animation ---
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