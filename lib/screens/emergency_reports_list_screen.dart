import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class EmergencyReportsListScreen extends StatefulWidget {
  const EmergencyReportsListScreen({super.key});

  @override
  State<EmergencyReportsListScreen> createState() =>
      _EmergencyReportsListScreenState();
}

class _EmergencyReportsListScreenState
    extends State<EmergencyReportsListScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.emergency, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Emergency Reports',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.getEmergencyReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load reports',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: const Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                      label: Text('Retry',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: Color(0xFF10B981), size: 56),
                  ),
                  const SizedBox(height: 20),
                  Text('No Emergency Reports',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text('All clear! No emergency incidents reported.',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF64748B), fontSize: 14)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reports.length} Active Emergency Report${reports.length != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        Text('Citizen-submitted accident reports',
                            style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFDC2626),
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return _EmergencyReportCard(report: reports[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmergencyReportCard extends StatefulWidget {
  final Map<String, dynamic> report;

  const _EmergencyReportCard({required this.report});

  @override
  State<_EmergencyReportCard> createState() => _EmergencyReportCardState();
}

class _EmergencyReportCardState extends State<_EmergencyReportCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy • h:mm a');
    final dateStr = widget.report['created_at'] != null
        ? formatter.format(
            DateTime.parse(widget.report['created_at']).toLocal())
        : 'Unknown';

    final description = widget.report['description'] ?? '';
    final location = widget.report['location_text'] ?? 'Unknown Location';
    final accidentId = widget.report['number_plate'] ?? 'Unknown';
    final imagePath = widget.report['image_path'];

    // Parse the description to extract emergency details
    String accidentName = '';
    String witnessContact = '';
    String extraDescription = '';
    if (description.startsWith('EMERGENCY:')) {
      final lines = description.split('\n');
      for (final line in lines) {
        if (line.startsWith('EMERGENCY:')) {
          accidentName = line.replaceFirst('EMERGENCY:', '').trim();
        } else if (line.startsWith('Witness Contact:')) {
          witnessContact = line.replaceFirst('Witness Contact:', '').trim();
        } else {
          extraDescription += line.trim();
        }
      }
    } else {
      extraDescription = description;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emergency,
                          color: Color(0xFFDC2626), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accidentName.isNotEmpty
                                ? accidentName
                                : 'Emergency Report',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF991B1B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(accidentId,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFDC2626)
                                      .withOpacity(0.7),
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('EMERGENCY',
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFECACA)),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.location_on,
                            size: 16, color: Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(location,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),

                if (witnessContact.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.phone,
                              size: 16, color: Color(0xFF10B981))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Witness Contact',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(witnessContact,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF334155),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                if (extraDescription.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.description,
                              size: 16, color: Color(0xFFF59E0B))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8))),
                            const SizedBox(height: 2),
                            Text(extraDescription,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF334155),
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Evidence toggle
                if (imagePath != null) ...[
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () =>
                        setState(() => _showDetails = !_showDetails),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF8FAFC)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library,
                              size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Text(
                              _showDetails
                                  ? 'Hide Evidence'
                                  : 'View Accident Scene Image',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          const SizedBox(width: 4),
                          Icon(
                              _showDetails
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF3B82F6),
                              size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (_showDetails) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 220,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Color(0xFF94A3B8), size: 40)),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
