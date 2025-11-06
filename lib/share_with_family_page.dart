// --- lib/share_with_family_page.dart (FINAL FULL UPDATED CODE) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'custom_toast.dart';

class ShareWithFamilyPage extends StatefulWidget {
  final String currentHubId;
  const ShareWithFamilyPage({super.key, required this.currentHubId});

  @override
  State<ShareWithFamilyPage> createState() => _ShareWithFamilyPageState();
}

class _ShareWithFamilyPageState extends State<ShareWithFamilyPage> {
  final TextEditingController _phoneController = TextEditingController();
  // දැනට UI එක පෙන්වීමට dummy data
  final List<Map<String, String>> _sharedUsers = [
    {'name': 'Wife', 'phone': '+94 77 123 4567'},
  ];

  // **** යාවත්කාලීන කරන ලද _inviteUser method එක ****
  void _inviteUser() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
       showCustomToast(context, "Please enter a phone number", isError: true);
       return;
    }

    // Phone number formatting logic
    if (!phone.startsWith('+')) {
       if (phone.startsWith('0')) {
         phone = '+94${phone.substring(1)}'; // 077... -> +9477...
       } else {
         phone = '+94$phone'; // 77... -> +9477...
       }
    }

    // Keyboard එක ඉවත් කර එය සම්පූර්ණයෙන්ම පහළට යන තෙක් රැඳී සිටීම
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _sharedUsers.add({'name': 'Pending...', 'phone': phone});
      _phoneController.clear();
    });

    // වඩාත් විශ්වාසදායක ලෙස පණිවිඩය පෙන්වීමට SnackBar භාවිතා කිරීම
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Invitation sent to $phone",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        centerTitle: true,
        title: Text("Share with Family", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Invite a family member", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "7x xxx xxxx",
                        prefixText: "+94 ",
                        prefixStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                        hintStyle: GoogleFonts.inter(color: Colors.white24),
                        filled: true, fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _inviteUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("INVITE", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text("Shared With:", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _sharedUsers.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade900.withOpacity(0.5),
                        child: Icon(Icons.person, color: Colors.blue.shade300),
                      ),
                      title: Text(_sharedUsers[index]['name']!, style: GoogleFonts.inter(color: Colors.white)),
                      subtitle: Text(_sharedUsers[index]['phone']!, style: GoogleFonts.inter(color: Colors.white54)),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: Colors.red.shade300),
                        onPressed: () {
                          setState(() => _sharedUsers.removeAt(index));
                          showCustomToast(context, "Removed user access");
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ).animate().fade().slideY(begin: 0.1),
        ),
      ),
    );
  }
}