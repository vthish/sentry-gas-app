// --- lib/my_usage_story_page.dart (FINAL FULL UPDATED CODE) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Make sure fl_chart:^0.68.0 is in pubspec.yaml
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
        title: Text(
          "My Usage Story",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // TabBar to switch views
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
          _buildThisWeekTab(),
          _buildMonthlyListTab(),  // Updated Tab 2
          _buildHistoryListTab(), // Updated Tab 3
        ],
      ),
    );
  }

  // --- Tab 1: This Week (As per Blueprint Page 4)  ---
  Widget _buildThisWeekTab() {
    // Mock data for 7 days usage (in grams)
    final List<double> weeklyUsage = [150, 120, 180, 90, 200, 160, 140];
    final double totalUsageKg = weeklyUsage.reduce((a, b) => a + b) / 1000;
    final int daysUsed = 8; // Example data

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 1. Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List.generate(7, (index) {
                  return PieChartSectionData(
                    value: weeklyUsage[index],
                    color: Colors.blue.withOpacity((index + 3) / 10),
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

          // 3. Daily List (Mock data)
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

  // --- Tab 2: Last 6 Months (As per Blueprint Page 4)  ---
  Widget _buildMonthlyListTab() {
    // Mock data for 6 months
    final List<Map<String, String>> monthlyUsage = [
      {'month': 'October', 'usage': '11.2 kg'},
      {'month': 'September', 'usage': '10.5 kg'},
      {'month': 'August', 'usage': '12.1 kg'},
      {'month': 'July', 'usage': '9.8 kg'},
      {'month': 'June', 'usage': '10.1 kg'},
      {'month': 'May', 'usage': '11.5 kg'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: monthlyUsage.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: const Icon(Icons.calendar_today, color: Colors.white54),
          title: Text(
            monthlyUsage[index]['month']!,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
          ),
          trailing: Text(
            monthlyUsage[index]['usage']!,
            style: GoogleFonts.inter(color: Colors.blue.shade300, fontSize: 16),
          ),
        ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
      },
    );
  }

  // --- Tab 3: Cylinder History (As per Blueprint Page 4)  ---
  Widget _buildHistoryListTab() {
    // Mock data for cylinder history
    final List<Map<String, String>> cylinderHistory = [
      {'date': 'Connected: Oct 15, 2025', 'duration': 'Used for 32 days'},
      {'date': 'Connected: Sep 12, 2025', 'duration': 'Used for 33 days'},
      {'date': 'Connected: Aug 09, 2025', 'duration': 'Used for 34 days'},
      {'date': 'Connected: Jul 07, 2025', 'duration': 'Used for 32 days'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: cylinderHistory.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: const Icon(Icons.history_toggle_off, color: Colors.white54),
          title: Text(
            cylinderHistory[index]['date']!,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            cylinderHistory[index]['duration']!,
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
      },
    );
  }
}