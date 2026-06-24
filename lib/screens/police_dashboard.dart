import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'emergency_reports_list_screen.dart';
import 'vehicle_registry_screen.dart';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  String _violationFilter = 'All';
  String _corruptionFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 10, bottom: 10),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VehicleRegistryScreen()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 14),
                      const SizedBox(width: 4),
                      Text('Registry', style: GoogleFonts.poppins(color: const Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
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
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('LOGOUT', style: GoogleFonts.poppins(color: const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700))),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                  labelColor: const Color(0xFF1E3A8A),
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  indicatorColor: const Color(0xFF3B82F6),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(icon: Icon(Icons.directions_car_rounded, size: 18), text: 'Violations'),
                    Tab(icon: Icon(Icons.gavel_rounded, size: 18), text: 'Corruption'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _ViolationsTab(
              dbService: _dbService,
              currentFilter: _violationFilter,
              onFilterChanged: (f) => setState(() => _violationFilter = f),
            ),
            _CorruptionTab(
              dbService: _dbService,
              currentFilter: _corruptionFilter,
              onFilterChanged: (f) => setState(() => _corruptionFilter = f),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VIOLATIONS TAB (existing logic, extracted)
// ─────────────────────────────────────────────
class _ViolationsTab extends StatefulWidget {
  final DatabaseService dbService;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _ViolationsTab({required this.dbService, required this.currentFilter, required this.onFilterChanged});

  @override
  State<_ViolationsTab> createState() => _ViolationsTabState();
}

class _ViolationsTabState extends State<_ViolationsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.dbService.getViolations();
  }

  void _refresh() {
    setState(() {
      _future = widget.dbService.getViolations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? [];
        int total = data.length;
        int pending = data.where((r) => r['status'] == 'pending').length;
        int approved = data.where((r) => r['status'] == 'approved').length;
        int rejected = data.where((r) => r['status'] == 'rejected').length;

        List<Map<String, dynamic>> filteredList = widget.currentFilter == 'All'
            ? data
            : data.where((r) => r['status'] == widget.currentFilter.toLowerCase()).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Live Intelligence', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.emergency, size: 14, color: Colors.white),
                    label: Text('Emergency', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 4,
                      shadowColor: const Color(0xFFEF4444).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyReportsListScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Expanded(
                child: _FeedContainer(
                  title: 'Incident Feed',
                  accentColor: const Color(0xFF3B82F6),
                  filters: const ['All', 'Pending', 'Approved', 'Rejected'],
                  currentFilter: widget.currentFilter,
                  onFilterChanged: widget.onFilterChanged,
                  onRefresh: () async => _refresh(),
                  itemCount: filteredList.length,
                  itemBuilder: (index) => _ViolationCard(
                    report: filteredList[index],
                    onApprove: () async {
                      await widget.dbService.updateViolationStatus(filteredList[index]['id'], 'approved');
                      _refresh();
                    },
                    onReject: () async {
                      await widget.dbService.updateViolationStatus(filteredList[index]['id'], 'rejected');
                      _refresh();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color bgColor, Color fgColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: fgColor, size: 18)),
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

// ─────────────────────────────────────────────
// CORRUPTION TAB (new)
// ─────────────────────────────────────────────
class _CorruptionTab extends StatefulWidget {
  final DatabaseService dbService;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _CorruptionTab({required this.dbService, required this.currentFilter, required this.onFilterChanged});

  @override
  State<_CorruptionTab> createState() => _CorruptionTabState();
}

class _CorruptionTabState extends State<_CorruptionTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.dbService.getAllCorruptionComplaints();
  }

  void _refresh() {
    setState(() {
      _future = widget.dbService.getAllCorruptionComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load complaints', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];
        int total = data.length;
        int pending = data.where((r) => r['status'] == 'pending').length;
        int approved = data.where((r) => r['status'] == 'approved').length;
        int rejected = data.where((r) => r['status'] == 'rejected').length;

        List<Map<String, dynamic>> filteredList = widget.currentFilter == 'All'
            ? data
            : data.where((r) => r['status'] == widget.currentFilter.toLowerCase()).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lokayukta Complaints', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Form I & II — Karnataka Anti-Corruption', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(total.toString(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, height: 1.0)),
                        Text('Total', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _buildStatChip('PENDING', pending.toString(), const Color(0xFFFFF7ED), const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildStatChip('APPROVED', approved.toString(), const Color(0xFFECFDF5), const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildStatChip('REJECTED', rejected.toString(), const Color(0xFFFEF2F2), const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _FeedContainer(
                  title: 'Complaint Feed',
                  accentColor: const Color(0xFF7C3AED),
                  filters: const ['All', 'Pending', 'Approved', 'Rejected'],
                  currentFilter: widget.currentFilter,
                  onFilterChanged: widget.onFilterChanged,
                  onRefresh: () async => _refresh(),
                  itemCount: filteredList.length,
                  itemBuilder: (index) => _CorruptionCard(
                    complaint: filteredList[index],
                    onApprove: () async {
                      await widget.dbService.updateCorruptionComplaintStatus(filteredList[index]['id'], 'approved');
                      _refresh();
                    },
                    onReject: () async {
                      await widget.dbService.updateCorruptionComplaintStatus(filteredList[index]['id'], 'rejected');
                      _refresh();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color bgColor, Color fgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(width: 4, height: 32, decoration: BoxDecoration(color: fgColor, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w700, height: 1.0)),
                Text(label, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED FEED CONTAINER WIDGET
// ─────────────────────────────────────────────
class _FeedContainer extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<String> filters;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _FeedContainer({
    required this.title,
    required this.accentColor,
    required this.filters,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: filters.map((filter) {
                        bool isSelected = currentFilter == filter;
                        return GestureDetector(
                          onTap: () => onFilterChanged(filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accentColor : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Text(
                              filter,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: itemCount == 0
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 48, color: const Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text('No records found', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: accentColor,
                    onRefresh: onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: itemCount,
                      itemBuilder: (_, index) => itemBuilder(index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VIOLATION CARD (unchanged logic)
// ─────────────────────────────────────────────
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
        ..initialize().then((_) { if (mounted) setState(() {}); });
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
    final dateStr = widget.report['created_at'] != null
        ? DateFormat('M/d/yyyy, h:mm:ss a').format(DateTime.parse(widget.report['created_at']).toLocal())
        : 'Unknown';
    final violationTypes = widget.report['violation_types'];
    String violationsText = violationTypes is List ? violationTypes.join(', ') : (violationTypes ?? '');
    final userId = widget.report['user_id'] != null ? '${widget.report['user_id'].toString().substring(0, 8)}...' : 'Unknown';

    final (Color statusBg, Color statusFg) = status == 'approved'
        ? (const Color(0xFFD1FAE5), const Color(0xFF059669))
        : status == 'rejected'
            ? (const Color(0xFFFEE2E2), const Color(0xFFDC2626))
            : (const Color(0xFFFEF3C7), const Color(0xFFD97706));

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.report['number_plate'] ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 18, letterSpacing: 1.0, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  _StatusBadge(status: status, bgColor: statusBg, fgColor: statusFg),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.person_pin, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(userId, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(icon: Icons.warning_amber_rounded, iconBg: const Color(0xFFFEF2F2), iconColor: const Color(0xFFEF4444), label: 'Violation Details', value: violationsText),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.location_on, iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF3B82F6), label: 'Location', value: widget.report['location_text'] ?? 'Unknown'),
              if ((widget.report['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.description, iconBg: const Color(0xFFFFF7ED), iconColor: const Color(0xFFF59E0B), label: 'Description', value: widget.report['description'].toString()),
              ],
              const SizedBox(height: 20),
              _EvidenceAccordion(
                isOpen: _showEvidence,
                onToggle: () => setState(() => _showEvidence = !_showEvidence),
                imagePath: widget.report['image_path'],
                videoController: _videoController,
                onVideoTap: () => setState(() => _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play()),
              ),
              if (status == 'pending') ...[
                const SizedBox(height: 24),
                _ActionButtons(onApprove: widget.onApprove, onReject: widget.onReject),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CORRUPTION CARD (new)
// ─────────────────────────────────────────────
class _CorruptionCard extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _CorruptionCard({required this.complaint, required this.onApprove, required this.onReject});

  @override
  State<_CorruptionCard> createState() => _CorruptionCardState();
}

class _CorruptionCardState extends State<_CorruptionCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.complaint['status'] ?? 'pending';
    final dateStr = widget.complaint['created_at'] != null
        ? DateFormat('M/d/yyyy, h:mm a').format(DateTime.parse(widget.complaint['created_at']).toLocal())
        : 'Unknown';

    final (Color statusBg, Color statusFg) = status == 'approved'
        ? (const Color(0xFFD1FAE5), const Color(0xFF059669))
        : status == 'rejected'
            ? (const Color(0xFFFEE2E2), const Color(0xFFDC2626))
            : (const Color(0xFFFEF3C7), const Color(0xFFD97706));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3E8FF), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF5FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.complaint['complainant_name'] ?? 'Unknown', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      Text(widget.complaint['complainant_phone'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  _StatusBadge(status: status, bgColor: statusBg, fgColor: statusFg),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8)),
                  child: Text('Lokayukta', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF3E8FF)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(
                icon: Icons.account_balance_rounded,
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
                label: 'Public Servant Complained Against',
                value: widget.complaint['public_servant_name'] ?? 'Unknown',
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.description_rounded,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF59E0B),
                label: 'Nature of Grievance',
                value: widget.complaint['grievance_nature'] ?? 'Not specified',
              ),
              const SizedBox(height: 18),

              // Expandable details accordion
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFAF5FF),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_rounded, size: 16, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Text(_showDetails ? 'Hide Full Complaint' : 'View Full Complaint Details',
                          style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(_showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF7C3AED), size: 18),
                    ],
                  ),
                ),
              ),

              if (_showDetails) ...[
                const SizedBox(height: 16),
                _DetailSection(
                  children: [
                    _DetailField('Complaint Facts', widget.complaint['complaint_facts']),
                    _DetailField('Complainant Address', widget.complaint['complainant_address']),
                    _DetailField('Servant Address / Office', widget.complaint['public_servant_address']),
                    if ((widget.complaint['witness_details'] ?? '').toString().isNotEmpty)
                      _DetailField('Witness Details', widget.complaint['witness_details']),
                    if ((widget.complaint['document_description'] ?? '').toString().isNotEmpty)
                      _DetailField('Document Description', widget.complaint['document_description']),
                    if ((widget.complaint['remarks'] ?? '').toString().isNotEmpty)
                      _DetailField('Remarks', widget.complaint['remarks']),
                  ],
                ),
                const SizedBox(height: 14),
                // Affidavit section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.badge_rounded, size: 14, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 6),
                        Text('Affidavit Details', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                      ]),
                      const SizedBox(height: 10),
                      _AffidavitRow('S/D/W of', widget.complaint['parent_name']),
                      _AffidavitRow('Age', widget.complaint['age']?.toString()),
                      _AffidavitRow('Profession', widget.complaint['profession']),
                      _AffidavitRow('Taluk / District', '${widget.complaint['taluk'] ?? ''}, ${widget.complaint['district'] ?? ''}'),
                      _AffidavitRow('Place', widget.complaint['place']),
                    ],
                  ),
                ),
                if (widget.complaint['document_path'] != null) ...[
                  const SizedBox(height: 14),
                  Text('Supporting Document', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.complaint['document_path'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (_, __, ___) => Container(height: 200, color: const Color(0xFFF1F5F9), child: const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8)))),
                    ),
                  ),
                ],
              ],

              if (status == 'pending') ...[
                const SizedBox(height: 20),
                _ActionButtons(onApprove: widget.onApprove, onReject: widget.onReject, approveLabel: 'Forward', rejectLabel: 'Dismiss'),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  final Color bgColor;
  final Color fgColor;

  const _StatusBadge({required this.status, required this.bgColor, required this.fgColor});

  @override
  Widget build(BuildContext context) {
    final icon = status == 'approved' ? Icons.check_circle : (status == 'rejected' ? Icons.cancel : Icons.hourglass_empty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: fgColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(children: [
        Icon(icon, size: 12, color: fgColor),
        const SizedBox(width: 4),
        Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: fgColor)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
        ])),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String approveLabel;
  final String rejectLabel;

  const _ActionButtons({required this.onApprove, required this.onReject, this.approveLabel = 'Approve', this.rejectLabel = 'Reject'});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: ElevatedButton(
        onPressed: onApprove,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          shadowColor: const Color(0xFF10B981).withOpacity(0.3),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(approveLabel, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      )),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton(
        onPressed: onReject,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(rejectLabel, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      )),
    ]);
  }
}

class _EvidenceAccordion extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final String? imagePath;
  final VideoPlayerController? videoController;
  final VoidCallback onVideoTap;

  const _EvidenceAccordion({required this.isOpen, required this.onToggle, this.imagePath, this.videoController, required this.onVideoTap});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12), color: const Color(0xFFF8FAFC)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library, size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(isOpen ? 'Hide Evidence' : 'View Submitted Evidence', style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF3B82F6), size: 18),
            ],
          ),
        ),
      ),
      if (isOpen) ...[
        const SizedBox(height: 16),
        if (imagePath != null) ...[
          Align(alignment: Alignment.centerLeft, child: Text('Captured Image', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imagePath!, fit: BoxFit.cover, width: double.infinity, height: 220,
              errorBuilder: (_, __, ___) => Container(height: 220, color: const Color(0xFFF1F5F9), child: const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))))),
          ),
          const SizedBox(height: 16),
        ],
        if (videoController != null && videoController!.value.isInitialized) ...[
          Align(alignment: Alignment.centerLeft, child: Text('Recorded Video', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: videoController!.value.aspectRatio,
              child: Stack(alignment: Alignment.bottomCenter, children: [
                VideoPlayer(videoController!),
                VideoProgressIndicator(videoController!, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFF3B82F6))),
                Center(child: InkWell(
                  onTap: onVideoTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                    child: Icon(videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                )),
              ]),
            ),
          ),
        ],
      ],
    ]);
  }
}

class _DetailSection extends StatelessWidget {
  final List<Widget> children;
  const _DetailSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED), letterSpacing: 0.3)),
        const SizedBox(height: 3),
        Text(value!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500, height: 1.4)),
      ]),
    );
  }
}

class _AffidavitRow extends StatelessWidget {
  final String label;
  final String? value;
  const _AffidavitRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
        const Text('  :  ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Expanded(child: Text(value!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
