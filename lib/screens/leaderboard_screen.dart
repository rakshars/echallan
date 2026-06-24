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

                    // ===== ALL ENTRIES TABLE =====
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: leaderboard.length,
                      itemBuilder: (context, index) {
                        final rank = index + 1;
                        final entry = leaderboard[index];
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
          Expanded(child: _buildPodiumCard(leaderboard[1], 2, 160, const Color(0xFFA8A8A8), const Color(0xFFBDBDBD))),
          const SizedBox(width: 8),
          // 1st Place
          Expanded(child: _buildPodiumCard(leaderboard[0], 1, 190, const Color(0xFFFFC107), const Color(0xFFFFD54F))),
          const SizedBox(width: 8),
          // 3rd Place
          Expanded(child: _buildPodiumCard(leaderboard[2], 3, 145, const Color(0xFFCD7F32), const Color(0xFFD4A574))),
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
            child: _buildPodiumCard(leaderboard[i], i + 1, 145, medalColors[i][0], medalColors[i][1]),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }

  Widget _buildLeaderboardRow(int rank, Map<String, dynamic> entry) {
    Color getRankColor() {
      if (rank == 1) return const Color(0xFFFEF3C7); // Gold tint
      if (rank == 2) return const Color(0xFFF1F5F9); // Silver tint
      if (rank == 3) return const Color(0xFFFFEDD5); // Bronze tint
      return Colors.white;
    }

    Color getRankTextColor() {
      if (rank == 1) return const Color(0xFFD97706);
      if (rank == 2) return const Color(0xFF64748B);
      if (rank == 3) return const Color(0xFFB45309);
      return const Color(0xFF64748B);
    }

    final String name = entry['full_name'] ?? 'Unknown';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: getRankColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rank <= 3 ? getRankTextColor().withOpacity(0.3) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: rank <= 3 ? getRankTextColor().withOpacity(0.1) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? getRankTextColor() : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, 
                  fontSize: 12, 
                  color: rank <= 3 ? Colors.white : const Color(0xFF64748B)
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Name
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Stats
          SizedBox(
            width: 45,
            child: Text(
              '${entry['total']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF1E293B)),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              '${entry['approved']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF10B981)),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              '${entry['rejected']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
