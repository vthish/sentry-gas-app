
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_toast.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background

class ShareWithFamilyPage extends StatefulWidget {
  final String currentHubId;
  const ShareWithFamilyPage({super.key, required this.currentHubId});

  @override
  State<ShareWithFamilyPage> createState() => _ShareWithFamilyPageState();
}

class _ShareWithFamilyPageState extends State<ShareWithFamilyPage> {
  final TextEditingController _phoneController = TextEditingController();

  final List<Map<String, String>> _sharedUsers = [
    {'name': 'Wife', 'phone': '+94 77 123 4567'},
  ];


  void _inviteUser() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showCustomToast(context, "Please enter a phone number", isError: true);
      return;
    }


    if (!phone.startsWith('+')) {
      if (phone.startsWith('0')) {
        phone = '+94${phone.substring(1)}'; // 077... -> +9477...
      } else {
        phone = '+94$phone'; // 77... -> +9477...
      }
    }


    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _sharedUsers.add({'name': 'Pending...', 'phone': phone});
      _phoneController.clear();
    });


    showCustomToast(context, "Invitation sent to $phone");
  }


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


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Share with Family",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop()),
      ),

      body: Stack(
        children: [
          _buildAnimatedBackground(), // <-- The animation


          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Invite a family member",
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 14))
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideX(begin: -0.1),
                    
                    const SizedBox(height: 8),


                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "7x xxx xxxx",
                              prefixText: "+94 ",
                              prefixStyle: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 16),
                              hintStyle: GoogleFonts.inter(color: Colors.white24),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1), // Glass fill

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade400),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        OutlinedButton(
                          onPressed: _inviteUser,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            side: BorderSide(color: Colors.blue.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                          child: Text("INVITE",
                              style:
                                  GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                    
                    const SizedBox(height: 40),
                    
                    Text("Shared With:",
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600))
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideX(begin: -0.1),

                    const SizedBox(height: 16),
                    

                    Expanded(
                      child: ListView.separated(
                        itemCount: _sharedUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12), // Use SizedBox for spacing
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: _glassmorphismCardDecoration(), // Glass card
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.blue.shade900.withOpacity(0.5),
                                child: Icon(Icons.person,
                                    color: Colors.blue.shade300),
                              ),
                              title: Text(_sharedUsers[index]['name']!,
                                  style: GoogleFonts.inter(color: Colors.white)),
                              subtitle: Text(_sharedUsers[index]['phone']!,
                                  style: GoogleFonts.inter(color: Colors.white54)),
                              trailing: IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.red.shade300),
                                onPressed: () {
                                  setState(
                                      () => _sharedUsers.removeAt(index));
                                  showCustomToast(context, "Removed user access");
                                },
                              ),
                            ),
                          )

                          .animate().fadeIn(delay: (400 + index * 100).ms).slideX(begin: 0.2); 
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
