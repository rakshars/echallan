import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class CorruptionComplaintScreen extends StatefulWidget {
  const CorruptionComplaintScreen({super.key});

  @override
  State<CorruptionComplaintScreen> createState() => _CorruptionComplaintScreenState();
}

class _CorruptionComplaintScreenState extends State<CorruptionComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _previousComplaint = false;
  File? _documentFile;

  // Form I controllers
  final _complainantNameCtrl = TextEditingController();
  final _complainantAddressCtrl = TextEditingController();
  final _complainantPhoneCtrl = TextEditingController();
  final _publicServantNameCtrl = TextEditingController();
  final _publicServantAddressCtrl = TextEditingController();
  final _complaintFactsCtrl = TextEditingController();
  final _grievanceNatureCtrl = TextEditingController();
  final _witnessDetailsCtrl = TextEditingController();
  final _documentDescCtrl = TextEditingController();
  final _documentSourceCtrl = TextEditingController();
  final _previousComplaintDetailsCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  // Form II controllers
  final _parentNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _residentialAddressCtrl = TextEditingController();
  final _talukCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _presentTalukCtrl = TextEditingController();
  final _presentDistrictCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  bool _declarationAccepted = false;

  @override
  void dispose() {
    _complainantNameCtrl.dispose();
    _complainantAddressCtrl.dispose();
    _complainantPhoneCtrl.dispose();
    _publicServantNameCtrl.dispose();
    _publicServantAddressCtrl.dispose();
    _complaintFactsCtrl.dispose();
    _grievanceNatureCtrl.dispose();
    _witnessDetailsCtrl.dispose();
    _documentDescCtrl.dispose();
    _documentSourceCtrl.dispose();
    _previousComplaintDetailsCtrl.dispose();
    _remarksCtrl.dispose();
    _parentNameCtrl.dispose();
    _ageCtrl.dispose();
    _professionCtrl.dispose();
    _residentialAddressCtrl.dispose();
    _talukCtrl.dispose();
    _districtCtrl.dispose();
    _presentTalukCtrl.dispose();
    _presentDistrictCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _documentFile = File(image.path));
    }
  }

  void _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the declaration before submitting.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('Not logged in');

      String? uploadedDocPath;
      if (_documentFile != null) {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        uploadedDocPath = await _dbService.uploadCorruptionDocument(
          _documentFile!, user.id, 'doc_$timestamp.jpg',
        );
      }

      await _dbService.createCorruptionComplaint(
        userId: user.id,
        complainantName: _complainantNameCtrl.text.trim(),
        complainantAddress: _complainantAddressCtrl.text.trim(),
        complainantPhone: _complainantPhoneCtrl.text.trim(),
        publicServantName: _publicServantNameCtrl.text.trim(),
        publicServantAddress: _publicServantAddressCtrl.text.trim(),
        complaintFacts: _complaintFactsCtrl.text.trim(),
        grievanceNature: _grievanceNatureCtrl.text.trim(),
        witnessDetails: _witnessDetailsCtrl.text.trim().isEmpty ? null : _witnessDetailsCtrl.text.trim(),
        documentDescription: _documentDescCtrl.text.trim().isEmpty ? null : _documentDescCtrl.text.trim(),
        documentPath: uploadedDocPath,
        documentSource: _documentSourceCtrl.text.trim().isEmpty ? null : _documentSourceCtrl.text.trim(),
        previousComplaint: _previousComplaint,
        previousComplaintDetails: _previousComplaint ? _previousComplaintDetailsCtrl.text.trim() : null,
        remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
        parentName: _parentNameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        profession: _professionCtrl.text.trim(),
        residentialAddress: _residentialAddressCtrl.text.trim(),
        taluk: _talukCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        presentTaluk: _presentTalukCtrl.text.trim().isEmpty ? null : _presentTalukCtrl.text.trim(),
        presentDistrict: _presentDistrictCtrl.text.trim().isEmpty ? null : _presentDistrictCtrl.text.trim(),
        place: _placeCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Corruption complaint submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Report Corruption',
          style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.close, size: 20, color: Color(0xFF4B5563)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gavel, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lokayukta Complaint Form',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Form No. I & II — Before the Lokayukta/Upa-Lokayukta for Karnataka',
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ===== FORM I: COMPLAINT =====
                    _buildFormHeader('FORM I — COMPLAINT'),
                    const SizedBox(height: 20),

                    // 1. Complainant Details
                    _buildSectionTitle(Icons.person, '1. Complainant Details', const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _buildTextField(_complainantNameCtrl, 'Full Name', required: true),
                    const SizedBox(height: 12),
                    _buildTextField(_complainantAddressCtrl, 'Address for Correspondence', maxLines: 3, required: true),
                    const SizedBox(height: 12),
                    _buildTextField(_complainantPhoneCtrl, 'Phone Number', keyboardType: TextInputType.phone, required: true),
                    const SizedBox(height: 24),

                    // 2. Public Servant Details
                    _buildSectionTitle(Icons.account_balance, '2. Public Servant Complained Against', const Color(0xFFDC2626)),
                    const SizedBox(height: 12),
                    _buildTextField(_publicServantNameCtrl, 'Name & Designation', required: true),
                    const SizedBox(height: 12),
                    _buildTextField(_publicServantAddressCtrl, 'Address / Office', maxLines: 3, required: true),
                    const SizedBox(height: 24),

                    // 3. Brief facts
                    _buildSectionTitle(Icons.description, '3. Brief Facts of the Complaint', const Color(0xFFF59E0B)),
                    const SizedBox(height: 8),
                    Text('(Complainant\'s affidavit in Form II to be enclosed)',
                      style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 11)),
                    const SizedBox(height: 12),
                    _buildTextField(_complaintFactsCtrl, 'Describe the facts...', maxLines: 5, required: true),
                    const SizedBox(height: 24),

                    // 4. Nature of Grievance
                    _buildSectionTitle(Icons.report_problem, '4. Nature of Grievance', const Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    _buildTextField(_grievanceNatureCtrl, 'Describe the nature of your grievance...', maxLines: 4, required: true),
                    const SizedBox(height: 24),

                    // 5. Witnesses
                    _buildSectionTitle(Icons.people, '5. Witness Details (Optional)', const Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    _buildTextField(_witnessDetailsCtrl, 'Names and addresses of witnesses...', maxLines: 3),
                    const SizedBox(height: 24),

                    // 6. Supporting Documents Description
                    _buildSectionTitle(Icons.folder_open, '6. Supporting Documents (Optional)', const Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    _buildTextField(_documentDescCtrl, 'Describe documents supporting your allegation...', maxLines: 3),
                    const SizedBox(height: 12),

                    // 7. Upload document image
                    GestureDetector(
                      onTap: _pickDocument,
                      child: Container(
                        height: _documentFile == null ? 70 : 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: _documentFile == null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white, shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                    child: const Icon(Icons.upload_file, color: Color(0xFF6366F1), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('Upload supporting document image', style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_documentFile!, fit: BoxFit.cover, width: double.infinity),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 8. Document source
                    _buildSectionTitle(Icons.search, '8. Document Source (Optional)', const Color(0xFF8B5CF6)),
                    const SizedBox(height: 8),
                    Text('If documents are not with you, specify where they can be obtained',
                      style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 11)),
                    const SizedBox(height: 12),
                    _buildTextField(_documentSourceCtrl, 'Office or individual who may have the documents...', maxLines: 2),
                    const SizedBox(height: 24),

                    // 9. Previous complaint
                    _buildSectionTitle(Icons.history, '9. Previous Complaint', const Color(0xFFF97316)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Have you filed a previous complaint to Lokayukta or any other authority?',
                                  style: GoogleFonts.inter(color: const Color(0xFF374151), fontSize: 13)),
                              ),
                              Switch(
                                value: _previousComplaint,
                                activeColor: const Color(0xFF7C3AED),
                                onChanged: (val) => setState(() => _previousComplaint = val),
                              ),
                            ],
                          ),
                          if (_previousComplaint) ...[
                            const SizedBox(height: 12),
                            _buildTextField(_previousComplaintDetailsCtrl,
                              'Provide details & result of the previous complaint...', maxLines: 3, required: true),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 10. Remarks
                    _buildSectionTitle(Icons.comment, '10. Remarks (Optional)', Colors.teal),
                    const SizedBox(height: 12),
                    _buildTextField(_remarksCtrl, 'Any additional remarks...', maxLines: 3),
                    const SizedBox(height: 36),

                    // ===== FORM II: AFFIDAVIT =====
                    _buildFormHeader('FORM II — COMPLAINANT\'S AFFIDAVIT'),
                    const SizedBox(height: 8),
                    Text('Personal details for the sworn affidavit',
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12)),
                    const SizedBox(height: 20),

                    _buildSectionTitle(Icons.badge, 'Personal Information', const Color(0xFF0EA5E9)),
                    const SizedBox(height: 12),
                    _buildTextField(_parentNameCtrl, 'Son / Daughter of (Parent/Guardian Name)', required: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_ageCtrl, 'Age', keyboardType: TextInputType.number, required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_professionCtrl, 'Profession', required: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_residentialAddressCtrl, 'Residential Address', maxLines: 3, required: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_talukCtrl, 'Taluk', required: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_districtCtrl, 'District', required: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Present Address (if different)',
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_presentTalukCtrl, 'Present Taluk')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_presentDistrictCtrl, 'Present District')),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Place & Declaration
                    _buildSectionTitle(Icons.place, 'Place & Declaration', const Color(0xFF059669)),
                    const SizedBox(height: 12),
                    _buildTextField(_placeCtrl, 'Place', required: true),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _declarationAccepted,
                            activeColor: const Color(0xFF7C3AED),
                            onChanged: (val) => setState(() => _declarationAccepted = val ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'I declare and affirm that the statements in this complaint petition are true to the best of my knowledge, information and belief.',
                              style: GoogleFonts.inter(color: const Color(0xFF92400E), fontSize: 12, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Submit & Cancel
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitComplaint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text('Submit Complaint', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFF3F4F6), side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF4B5563), fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1F2937)))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, bool required = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
          filled: true, fillColor: Colors.white,
        ),
        validator: required
            ? (value) => (value == null || value.trim().isEmpty) ? 'This field is required' : null
            : null,
      ),
    );
  }
}
