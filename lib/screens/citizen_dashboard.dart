import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'report_violation_screen.dart';
import 'corruption_complaint_screen.dart';
import 'leaderboard_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  String _userName = 'Citizen';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _userId = user.id;
          _userName = user.userMetadata?['full_name'] ?? 'Citizen';
        });
      }
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Fetches both traffic violations and corruption complaints, merges and sorts by date
  Future<List<Map<String, dynamic>>> _getAllReports() async {
    final violations = await _dbService.getUserViolations(_userId);
    List<Map<String, dynamic>> corruptionComplaints = [];
    try {
      corruptionComplaints = await _dbService.getUserCorruptionComplaints(_userId);
    } catch (_) {
      // Table may not exist yet
    }

    // Tag each report with its type
    final taggedViolations = violations.map((r) => {...r, '_type': 'violation'}).toList();
    final taggedCorruption = corruptionComplaints.map((r) => {...r, '_type': 'corruption'}).toList();

    final all = [...taggedViolations, ...taggedCorruption];
    all.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $_userName 👋', style: GoogleFonts.poppins(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Keep your city safe', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); 
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gamification / Trust Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.shield, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Contributor', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('You are actively helping reduce traffic violations in your area.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ====== TWO ACTION CARDS ======
                // 1. Report Traffic Violation
                _buildActionCard(
                  icon: Icons.camera_alt_outlined,
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Report Traffic Violation',
                  subtitle: 'Report overspeeding, parking issues, etc.',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportViolationScreen()));
                  },
                ),
                const SizedBox(height: 12),

                // 2. Report Corruption
                _buildActionCard(
                  icon: Icons.gavel,
                  iconBgColor: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Report Corruption',
                  subtitle: 'File a Lokayukta complaint against a public servant',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CorruptionComplaintScreen()));
                  },
                ),
                const SizedBox(height: 12),

                // 3. Leaderboard
                _buildActionCard(
                  icon: Icons.emoji_events,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Leaderboard',
                  subtitle: 'See top citizen reporters and your rank',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
                  },
                ),

                const SizedBox(height: 32),
                
                // My Reports Header
                Text('My Recent Reports', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const SizedBox(height: 12),

                // Reports Feed — merged violations + corruption complaints
                if (_userId.isNotEmpty)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getAllReports(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading reports', style: GoogleFonts.inter(color: Colors.red)));
                      }
                      
                      final reports = snapshot.data ?? [];
                      if (reports.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('You haven\'t submitted any reports yet.', style: GoogleFonts.inter(color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          if (report['_type'] == 'corruption') {
                            return _buildCorruptionReportItem(report);
                          }
                          return _buildReportItem(report);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final status = report['status'] ?? 'pending';
    final formatter = DateFormat('MMM d, yyyy');
    final dateStr = report['created_at'] != null 
        ? formatter.format(DateTime.parse(report['created_at']).toLocal())
        : 'Unknown Date';

    Color statusBgColor = const Color(0xFFFEF3C7);
    Color statusTextColor = const Color(0xFFD97706);
    IconData statusIcon = Icons.hourglass_empty;

    if (status == 'approved') {
      statusBgColor = const Color(0xFFD1FAE5);
      statusTextColor = const Color(0xFF059669);
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.directions_car, color: const Color(0xFF6B7280), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['number_plate'] ?? 'Unknown Vehicle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Icon(statusIcon, size: 12, color: statusTextColor),
                const SizedBox(width: 4),
                Text(
                  status[0].toUpperCase() + status.substring(1), 
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCorruptionReportItem(Map<String, dynamic> report) {
    final status = report['status'] ?? 'pending';
    final formatter = DateFormat('MMM d, yyyy');
    final dateStr = report['created_at'] != null 
        ? formatter.format(DateTime.parse(report['created_at']).toLocal())
        : 'Unknown Date';

    Color statusBgColor = const Color(0xFFFEF3C7);
    Color statusTextColor = const Color(0xFFD97706);
    IconData statusIcon = Icons.hourglass_empty;

    if (status == 'approved') {
      statusBgColor = const Color(0xFFD1FAE5);
      statusTextColor = const Color(0xFF059669);
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.gavel, color: Color(0xFF7C3AED), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Corruption Complaint', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text('vs ${report['public_servant_name'] ?? 'Unknown'}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Icon(statusIcon, size: 12, color: statusTextColor),
                const SizedBox(width: 4),
                Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
