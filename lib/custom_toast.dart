

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'dart:ui'; // For BackdropFilter (Glass effect)


void showCustomToast(BuildContext context, String message, {bool isError = false}) {
  showOverlayNotification(
    (context) {

      return Material(
        color: Colors.transparent,
        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0), 
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: BackdropFilter( // Glass / Blur effect
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(

                  color: Colors.black.withOpacity(0.4), 
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    Icon(
                      isError ? Icons.error_outline : Icons.check_circle_outline,

                      color: isError ? Colors.red.shade500 : Colors.green.shade500, 
                      size: 28,
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.inter(
                          color: Colors.white, // Text color remains white for high contrast
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
    duration: const Duration(seconds: 4), // Auto close after 4 seconds
    position: NotificationPosition.top, // Pop-up from the top
  );
}
