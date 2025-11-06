// --- lib/my_usage_story_page.dart (Initial UI) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart සඳහා පැකේජයක් අවශ්‍ය වේ
import 'package:flutter_animate/flutter_animate.dart';

class MyUsageStoryPage extends StatefulWidget {
  final String currentHubId;
  const MyUsageStoryPage({super.key, required this.currentHubId});

  @override
  State<MyUsageStoryPage> createState() => _MyUsageStoryPageState();
}

class _MyUsageStoryPageState extends State<MyUsageStoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("My Usage Story", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "This Week"),
            Tab(text: "Last 6 Months"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThisWeekTab(),      // Tab 1
          _buildComingSoonTab(),    // Tab 2 (දැනට)
          _buildComingSoonTab(),    // Tab 3 (දැනට)
        ],
      ),
    );
  }

  // --- Tab 1: This Week (Mock Data සමග) ---
  Widget _buildThisWeekTab() {
    // දත්ත: දින 7 සඳහා භාවිතය (ග්‍රෑම් වලින්)
    final List<double> weeklyUsage = [150, 120, 180, 90, 200, 160, 140];
    final double totalUsageKg = weeklyUsage.reduce((a, b) => a + b) / 1000;
    final int daysUsed = 8; // උදාහරණයක් ලෙස [cite: 82]

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 1. Pie Chart (සරලව) [cite: 69]
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List.generate(7, (index) {
                  return PieChartSectionData(
                    value: weeklyUsage[index],
                    color: Colors.blue.withOpacity((index + 3) / 10), // වෙනස් වර්ණ
                    radius: 50,
                    showTitle: false,
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ).animate().scale(),

          const SizedBox(height: 30),

          // 2. Summary Text [cite: 73, 81-83]
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Total used this week: ${totalUsageKg.toStringAsFixed(1)}kg",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  "You've been using this cylinder for $daysUsed days.",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fade().slideY(begin: 0.2),

          const SizedBox(height: 30),

          // 3. Daily List [cite: 80]
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(days[index][0], style: GoogleFonts.inter(color: Colors.blue)),
                  ),
                  title: Text(days[index], style: GoogleFonts.inter(color: Colors.white)),
                  trailing: Text("${weeklyUsage[index].toInt()}g", style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab() {
    return Center(
      child: Text("Coming Soon...", style: GoogleFonts.inter(color: Colors.white54, fontSize: 18)),
    );
  }
}