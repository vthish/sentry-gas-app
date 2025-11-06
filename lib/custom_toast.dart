// --- lib/custom_toast.dart ---

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'dart:ui'; // BackdropFilter (Glass effect) සඳහා

// අපේ custom pop-up එක පෙන්වන ප්‍රධාන function එක
void showCustomToast(BuildContext context, String message, {bool isError = false}) {
  showOverlayNotification(
    (context) {
      // මෙතන තමයි අපේ "Liquid Glass" widget එක හදන්නේ
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter( // Glass / Blur effect එක
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Glass පාට
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon එක (Error or Success)
                    Icon(
                      isError ? Icons.error_outline : Icons.check_circle_outline,
                      color: isError ? Colors.red.shade300 : Colors.green.shade300,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    // Message එක
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    duration: const Duration(seconds: 4), // තත්පර 4කින් auto close වීම
    position: NotificationPosition.top, // උඩ ඉඳන් pop-up වීම
  );
}