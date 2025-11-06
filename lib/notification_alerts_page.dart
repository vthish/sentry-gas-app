// --- lib/notification_alerts_page.dart (FINAL FIXED - Added material.dart) ---

import 'package:flutter/material.dart'; // <-- **** මේ import එක අනිවාර්යයෙන්ම ඕන ****
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_toast.dart';

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
         // Error එකක් ආවත් default values එක්ක load වෙන්න ඉඩ දෙනවා
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Notification Alerts",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildAlertItem(
                    title: "Gas Leak Alerts",
                    value: _gasLeakAlert,
                    onChanged: (newValue) {
                      setState(() => _gasLeakAlert = newValue);
                      _saveSetting('gasLeakAlert', newValue);
                    },
                  ),
                  const Divider(color: Colors.white24, height: 30),
                  _buildAlertItem(
                    title: "Low Gas Warning (20%)",
                    value: _lowGasWarning,
                    onChanged: (newValue) {
                      setState(() => _lowGasWarning = newValue);
                      _saveSetting('lowGasWarning', newValue);
                    },
                  ),
                  const Divider(color: Colors.white24, height: 30),
                  _buildAlertItem(
                    title: "Hub is Offline",
                    value: _hubOfflineAlert,
                    onChanged: (newValue) {
                      setState(() => _hubOfflineAlert = newValue);
                      _saveSetting('hubOfflineAlert', newValue);
                    },
                  ),
                ].animate(interval: 100.ms).fade(duration: 400.ms).slideX(begin: -0.1),
              ),
            ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              inactiveThumbColor: Colors.white54,
              trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}