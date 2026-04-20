import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  String _currentFilter = 'All';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra light clean background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Police Command', style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
                Text('E-Challan Management', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Active Officer', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                  Text('On Duty', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('LOGOUT', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700))),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _dbService.getViolations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data ?? [];
            
            // Calculate stats
            int total = data.length;
            int pending = data.where((r) => r['status'] == 'pending').length;
            int approved = data.where((r) => r['status'] == 'approved').length;
            int rejected = data.where((r) => r['status'] == 'rejected').length;

            // Filter data
            List<Map<String, dynamic>> filteredList = data;
            if (_currentFilter != 'All') {
              filteredList = data.where((r) => r['status'] == _currentFilter.toLowerCase()).toList();
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Summary Cards Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Live Intelligence', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.emergency, size: 14, color: Colors.white),
                        label: Text('Emergency', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          elevation: 4,
                          shadowColor: const Color(0xFFEF4444).withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard('TOTAL', total.toString(), const Color(0xFFEFF6FF), const Color(0xFF3B82F6), Icons.data_usage_rounded),
                      const SizedBox(width: 8),
                      _buildSummaryCard('PENDING', pending.toString(), const Color(0xFFFFF7ED), const Color(0xFFF59E0B), Icons.pending_actions_rounded),
                      const SizedBox(width: 8),
                      _buildSummaryCard('APPROVED', approved.toString(), const Color(0xFFECFDF5), const Color(0xFF10B981), Icons.verified_rounded),
                      const SizedBox(width: 8),
                      _buildSummaryCard('REJECTED', rejected.toString(), const Color(0xFFFEF2F2), const Color(0xFFEF4444), Icons.gpp_bad_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // White Container for list
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Column(
                        children: [
                          // Filter Header
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Incident Feed', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: ['All', 'Pending', 'Approved', 'Rejected'].map((filter) {
                                        bool isSelected = _currentFilter == filter;
                                        return GestureDetector(
                                          onTap: () => setState(() => _currentFilter = filter),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                                              boxShadow: isSelected 
                                                ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                                : null,
                                            ),
                                            child: Text(
                                              filter, 
                                              style: GoogleFonts.inter(
                                                fontSize: 12, 
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                                                color: isSelected ? Colors.white : const Color(0xFF64748B)
                                              )
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          
                          // Feed List View
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                setState(() {}); // Trigger FutureBuilder to rebuild
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  return _ViolationCard(
                                    report: filteredList[index],
                                    onApprove: () async {
                                      await _dbService.updateViolationStatus(filteredList[index]['id'], 'approved');
                                      setState(() {}); // Refresh data
                                    },
                                    onReject: () async {
                                      await _dbService.updateViolationStatus(filteredList[index]['id'], 'rejected');
                                      setState(() {}); // Refresh data
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        )
      )
    );
  }

  Widget _buildSummaryCard(String title, String value, Color bgColor, Color fgColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: fgColor, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.w700, height: 1.0)),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ViolationCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ViolationCard({required this.report, required this.onApprove, required this.onReject});

  @override
  State<_ViolationCard> createState() => _ViolationCardState();
}

class _ViolationCardState extends State<_ViolationCard> {
  bool _showEvidence = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.report['video_path'] != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.report['video_path']))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.report['status'] ?? 'pending';
    final formatter = DateFormat('M/d/yyyy, h:mm:ss a');
    final dateStr = widget.report['created_at'] != null 
        ? formatter.format(DateTime.parse(widget.report['created_at']).toLocal())
        : 'Unknown';

    final violationTypes = widget.report['violation_types'];
    String violationsText = '';
    if (violationTypes is List) {
      violationsText = violationTypes.join(', ');
    } else if (violationTypes is String) {
      violationsText = violationTypes;
    }

    final userId = widget.report['user_id'] != null ? widget.report['user_id'].toString().substring(0, 8) + '...' : 'Unknown';

    Color statusBgColor = const Color(0xFFFEF3C7);
    Color statusTextColor = const Color(0xFFD97706);
    if (status == 'approved') {
      statusBgColor = const Color(0xFFD1FAE5);
      statusTextColor = const Color(0xFF059669);
    } else if (status == 'rejected') {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.report['number_plate'] ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 18, letterSpacing: 1.0, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: statusTextColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                      child: Row(
                        children: [
                          Icon(status == 'approved' ? Icons.check_circle : (status == 'rejected' ? Icons.cancel : Icons.hourglass_empty), size: 12, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: statusTextColor)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text('$dateStr', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.person_pin, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('$userId', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          
          // Body Data
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Violation Details', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8).withOpacity(0.8))),
                      const SizedBox(height: 2),
                      Text(violationsText, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    ])),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.location_on, size: 16, color: Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Location', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8).withOpacity(0.8))),
                      const SizedBox(height: 2),
                      Text(widget.report['location_text'] ?? "Unknown", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), fontWeight: FontWeight.w500)),
                    ])),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Evidence Accordion
                InkWell(
                  onTap: () => setState(() => _showEvidence = !_showEvidence),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF8FAFC)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 16, color: const Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(_showEvidence ? 'Hide Evidence' : 'View Submitted Evidence', style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 4),
                        Icon(_showEvidence ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF3B82F6), size: 18),
                      ],
                    ),
                  ),
                ),

                if (_showEvidence) ...[
                  const SizedBox(height: 16),
                  if (widget.report['image_path'] != null) ...[
                    Text('Captured Image', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(widget.report['image_path'], fit: BoxFit.cover, width: double.infinity, height: 220, 
                        errorBuilder: (context, error, stackTrace) => Container(height: 220, color: const Color(0xFFF1F5F9), child: const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))))),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_videoController != null && _videoController!.value.isInitialized) ...[
                    Text('Recorded Video', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(_videoController!),
                            VideoProgressIndicator(_videoController!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFF3B82F6))),
                            Center(
                              child: InkWell(
                                onTap: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play()),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                  child: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ]
                ],

                if (status == 'pending') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(
                        onPressed: widget.onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Approve', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(
                        onPressed: widget.onReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Reject', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      )),
                    ],
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
