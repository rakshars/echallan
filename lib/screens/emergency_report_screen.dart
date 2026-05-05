import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';

class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _accidentNameController = TextEditingController();
  final _witnessContactController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _locationError;
  String? _currentAddress;
  double? _currentLat;
  double? _currentLng;

  late String _accidentId;

  @override
  void initState() {
    super.initState();
    _accidentId = 'ACC${DateTime.now().millisecondsSinceEpoch}';
    _fetchLiveLocation();
  }

  @override
  void dispose() {
    _accidentNameController.dispose();
    _witnessContactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Upload Accident Scene Image',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _getImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        _getImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _fetchLiveLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable them in settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            _currentAddress =
                '${place.locality}, ${place.administrativeArea}, ${place.country}';
          } else {
            _currentAddress = 'Unknown Location';
          }
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString().replaceAll('Exception: ', '');
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload an accident scene image.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_currentLat == null || _currentLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please wait for location to be fetched.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image with anonymous user folder
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String? uploadedImagePath = await _dbService.uploadMedia(
          _imageFile!, 'emergency', 'accident_$timestamp.jpg');

      await _dbService.createEmergencyReport(
        accidentId: _accidentId,
        accidentName: _accidentNameController.text.trim(),
        witnessContact: _witnessContactController.text.trim(),
        description: _descriptionController.text.trim(),
        locationText: _currentAddress ?? 'Unknown Location',
        locationLat: _currentLat!,
        locationLng: _currentLng!,
        imagePath: uploadedImagePath,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF10B981), size: 48),
                ),
                const SizedBox(height: 16),
                Text('Report Submitted!',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: const Color(0xFF1F2937))),
                const SizedBox(height: 8),
                Text(
                  'Your emergency report has been submitted successfully. Emergency services will be notified.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text('ID: $_accidentId',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Done',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error submitting report: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Emergency Help / Report Accident',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Back',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFDC2626)),
                  const SizedBox(height: 16),
                  Text('Submitting report...',
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emergency contact numbers
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEmergencyContact('Police', '100', Icons.local_police),
                          Container(
                              width: 1,
                              height: 30,
                              color: const Color(0xFFFCA5A5)),
                          _buildEmergencyContact(
                              'Ambulance', '108', Icons.local_hospital),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: -0.1),
                    const SizedBox(height: 24),

                    // Upload Accident Information header
                    Text('Upload Accident Information',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: const Color(0xFF1F2937)))
                        .animate()
                        .fade(duration: 400.ms, delay: 100.ms),
                    const SizedBox(height: 20),

                    // Accident Name
                    _buildLabel('Accident Name'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _accidentNameController,
                      hint: 'e.g. hit and run, pile-up...',
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter accident name'
                          : null,
                    ).animate().fade(duration: 400.ms, delay: 150.ms),
                    const SizedBox(height: 20),

                    // Accident ID (read-only)
                    _buildLabel('Accident ID'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(_accidentId,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                    ).animate().fade(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 20),

                    // Upload Image
                    _buildLabel('Upload Accident Scene Images'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: _imageFile != null ? 200 : 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.5,
                              style: BorderStyle.solid),
                        ),
                        child: _imageFile == null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Browse...',
                                        style: GoogleFonts.inter(
                                            color: const Color(0xFF374151),
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('No file chosen',
                                      style: GoogleFonts.inter(
                                          color: const Color(0xFF9CA3AF))),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_imageFile!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 200),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _imageFile = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ).animate().fade(duration: 400.ms, delay: 250.ms),
                    const SizedBox(height: 20),

                    // Witness Contact Number
                    _buildLabel('Witness Contact Number'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _witnessContactController,
                      hint: 'e.g. 8000000000',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter a contact number'
                          : null,
                    ).animate().fade(duration: 400.ms, delay: 300.ms),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Description (Optional)'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _descriptionController,
                      hint: 'Describe the accident...',
                      maxLines: 3,
                    ).animate().fade(duration: 400.ms, delay: 350.ms),
                    const SizedBox(height: 24),

                    // Location
                    _buildLabel('Location'),
                    const SizedBox(height: 8),
                    if (_currentLat != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Text('Location Captured Successfully',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF065F46),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'address: $_currentAddress\nlatitude: ${_currentLat!.toStringAsFixed(5)}, longitude: ${_currentLng!.toStringAsFixed(5)}',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF065F46), fontSize: 12),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 400.ms, delay: 400.ms)
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            if (_locationError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(_locationError!,
                                    style: GoogleFonts.inter(
                                        color: Colors.red, fontSize: 12),
                                    textAlign: TextAlign.center),
                              ),
                            ElevatedButton.icon(
                              onPressed:
                                  _isLoadingLocation ? null : _fetchLiveLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.my_location,
                                      color: Colors.white, size: 18),
                              label: Text(
                                  _isLoadingLocation
                                      ? 'Fetching GPS...'
                                      : 'Get Current Location',
                                  style: const TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 400.ms, delay: 400.ms),

                    const SizedBox(height: 40),

                    // Submit Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text('Submit Accident Report',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ).animate().fade(duration: 500.ms, delay: 500.ms).scale(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF374151)));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
            color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF3B82F6), width: 2)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildEmergencyContact(String label, String number, IconData icon) {
    return GestureDetector(
      onTap: () => _makePhoneCall(number),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF991B1B))),
              Text(number,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: const Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }
}
