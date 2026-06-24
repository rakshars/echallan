import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Leaderboard',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Icon(Icons.emoji_events, size: 80, color: Colors.white.withOpacity(0.15)),
                    ),
                    Positioned(
                      right: 70,
                      top: 40,
                      child: Icon(Icons.star, size: 30, color: Colors.white.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbService.getLeaderboard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(64),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text('Error loading leaderboard', style: GoogleFonts.inter(color: Colors.red)),
                          const SizedBox(height: 8),
                          Text('Make sure user_profiles table exists in Supabase', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final leaderboard = snapshot.data ?? [];

                if (leaderboard.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No reports yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                          const SizedBox(height: 8),
                          Text('Be the first to report a violation!', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 20),

                    // ===== TOP 3 PODIUM =====
                    if (leaderboard.length >= 3) _buildPodium(leaderboard)
                    else _buildSmallPodium(leaderboard),

                    const SizedBox(height: 24),

                    // ===== Column Headers =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 32, child: Text('#', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF3B82F6)))),
                            Expanded(child: Text('Citizen', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF3B82F6)))),
                            SizedBox(width: 50, child: Text('Total', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF3B82F6)))),
                            SizedBox(width: 50, child: Text('  ✅', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF10B981)))),
                            SizedBox(width: 50, child: Text('  ❌', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFFEF4444)))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ===== REMAINING ENTRIES =====
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: leaderboard.length > 3 ? leaderboard.length - 3 : 0,
                      itemBuilder: (context, index) {
                        final rank = index + 4;
                        final entry = leaderboard[index + 3];
                        return _buildLeaderboardRow(rank, entry);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> leaderboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(child: _buildPodiumCard(leaderboard[1], 2, 130, const Color(0xFFA8A8A8), const Color(0xFFBDBDBD))),
          const SizedBox(width: 8),
          // 1st Place
          Expanded(child: _buildPodiumCard(leaderboard[0], 1, 160, const Color(0xFFFFC107), const Color(0xFFFFD54F))),
          const SizedBox(width: 8),
          // 3rd Place
          Expanded(child: _buildPodiumCard(leaderboard[2], 3, 110, const Color(0xFFCD7F32), const Color(0xFFD4A574))),
        ],
      ),
    );
  }

  Widget _buildSmallPodium(List<Map<String, dynamic>> leaderboard) {
    final medalColors = [
      [const Color(0xFFFFC107), const Color(0xFFFFD54F)],
      [const Color(0xFFA8A8A8), const Color(0xFFBDBDBD)],
      [const Color(0xFFCD7F32), const Color(0xFFD4A574)],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(leaderboard.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPodiumCard(leaderboard[i], i + 1, 120, medalColors[i][0], medalColors[i][1]),
          );
        }),
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> entry, int rank, double height, Color primaryColor, Color secondaryColor) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal = medals[rank - 1];

    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, primaryColor.withOpacity(0.08)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            entry['full_name'] ?? 'Unknown',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1F2937)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry['total']} reports',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: primaryColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✅${entry['approved']}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text('❌${entry['rejected']}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, Map<String, dynamic> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry['full_name'] ?? 'Unknown',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${entry['total']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B)),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${entry['approved']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF10B981)),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${entry['rejected']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
