import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class ReportViolationScreen extends StatefulWidget {
  const ReportViolationScreen({super.key});

  @override
  State<ReportViolationScreen> createState() => _ReportViolationScreenState();
}

class _ReportViolationScreenState extends State<ReportViolationScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  File? _videoFile;
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isScanningAi = false;
  bool _isLoadingLocation = false;
  String? _locationError;
  String? _currentAddress;
  double? _currentLat;
  double? _currentLng;

  final List<String> _availableViolations = [
    'Accident', 'Overspeeding', 'No Parking', 
    'Red Light', 'Wrong Lane', 'Without Helmet', 
    'Rash Driving', 'Document Violation'
  ];
  final List<String> _selectedViolations = [];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        setState(() {
          _imageFile = File(image.path);
          _isScanningAi = true;
          _numberPlateController.clear();
        });
      }

      try {
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFile(_imageFile!));
        
        // Scan for an Indian License Plate Format using Regex
        // e.g. MH 12 AB 1234 or KA01HG1234 or DL-11-CA-1111
        final regex = RegExp(r'[A-Z]{2}[-\s]?[0-9]{1,2}[-\s]?[A-Z]{1,3}[-\s]?[0-9]{4}');
        String? detectedPlate;

        for (TextBlock block in recognizedText.blocks) {
          final text = block.text.toUpperCase().replaceAll('\n', ' ');
          if (regex.hasMatch(text)) {
            detectedPlate = regex.stringMatch(text);
            break;
          }
        }

        if (mounted) {
          setState(() {
            if (detectedPlate != null) {
              _numberPlateController.text = detectedPlate.replaceAll(RegExp(r'[-\s]'), '');
            }
            _isScanningAi = false;
          });
        }
        textRecognizer.close();
      } catch (e) {
        if (mounted) {
          setState(() {
            _isScanningAi = false;
          });
        }
      }
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoFile = File(video.path);
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
        throw Exception('Location services are disabled. Please enable them in settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            _currentAddress = '${place.locality}, ${place.administrativeArea}, ${place.country}';
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

  void _submitReport() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image.')));
      return;
    }
    if (_selectedViolations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one violation type.')));
      return;
    }
    if (_currentLat == null || _currentLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fetch your live location first.')));
      return;
    }
    if (_numberPlateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Number plate is required.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('Not logged in');

      // Upload files
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String? uploadedImagePath = await _dbService.uploadMedia(_imageFile!, user.id, 'image_$timestamp.jpg');
      
      String? uploadedVideoPath;
      if (_videoFile != null) {
        uploadedVideoPath = await _dbService.uploadMedia(_videoFile!, user.id, 'video_$timestamp.mp4');
      }

      // Save to database
      await _dbService.createViolationReport(
        userId: user.id,
        numberPlate: _numberPlateController.text.trim(),
        violationTypes: _selectedViolations,
        locationText: _currentAddress ?? 'Unknown Location',
        locationLat: _currentLat!,
        locationLng: _currentLng!,
        description: _descriptionController.text.trim(),
        imagePath: uploadedImagePath,
        videoPath: uploadedVideoPath,
      );

      // Notify vehicle owner if registered
      Map<String, dynamic>? owner;
      try {
        owner = await _dbService.notifyVehicleOwnerIfRegistered(
          numberPlate: _numberPlateController.text.trim(),
          violationTypes: _selectedViolations,
          location: _currentAddress ?? 'Unknown Location',
          description: _descriptionController.text.trim(),
          imagePath: uploadedImagePath,
        );
      } catch (_) {
        // Notification is non-critical; don't block the report
      }

      if (mounted) {
        if (owner != null) {
          // Show notification success dialog
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Owner Notified!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The vehicle owner has been notified about this violation.',
                    style: GoogleFonts.inter(color: const Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 8),
                            Text(owner!['owner_name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
                          ],
                        ),
                        if (owner!['owner_email'] != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(owner!['owner_email'], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)))),
                            ],
                          ),
                        ],
                        if (owner!['owner_phone'] != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              Text(owner!['owner_phone'], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Done', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Challan reported successfully!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
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
        title: Text('Report Violation', style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.close, size: 20, color: Color(0xFF4B5563))
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(Icons.camera_alt, 'Upload Vehicle Image', Colors.blue),
              const SizedBox(height: 12),
              _buildFileUploader(
                file: _imageFile, 
                onTap: _pickImage, 
                placeholder: 'Browse image'
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(Icons.videocam, 'Upload Video (optional)', Colors.indigo),
              const SizedBox(height: 12),
              _buildFileUploader(
                file: _videoFile, 
                onTap: _pickVideo, 
                placeholder: _videoFile != null ? _videoFile!.path.split('/').last : 'Browse...',
                isVideo: true,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(Icons.directions_car, 'Vehicle Number Plate', Colors.orange),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextFormField(
                  controller: _numberPlateController,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937), fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. MH12AB1234',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _isScanningAi 
                        ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) 
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (_isScanningAi)
                Text('🤖 AI scanning image for number plate...', style: GoogleFonts.inter(color: const Color(0xFF3B82F6), fontSize: 12))
              else
                Text('✓ Auto-detects on image upload (Edit if needed)', style: GoogleFonts.inter(color: Colors.green, fontSize: 12)),
              const SizedBox(height: 24),

              _buildSectionTitle(Icons.local_offer, 'Violation Type', Colors.purple),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: _availableViolations.map((v) {
                  final isSelected = _selectedViolations.contains(v);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      label: Text(v, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF4B5563))),
                      selected: isSelected,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: const Color(0xFFF9FAFB),
                      elevation: isSelected ? 4 : 0,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                      side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedViolations.add(v);
                          } else {
                            _selectedViolations.remove(v);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              if (_selectedViolations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('✓ Selected: ${_selectedViolations.join(", ")}', style: GoogleFonts.inter(color: Colors.green, fontSize: 12)),
              ],
              const SizedBox(height: 24),

              _buildSectionTitle(Icons.pin_drop, 'Location', Colors.red),
              const SizedBox(height: 12),
              if (_currentLat != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✓ Location Captured Successfully', style: GoogleFonts.inter(color: const Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('$_currentAddress\nLat: ${_currentLat!.toStringAsFixed(6)}, Long: ${_currentLng!.toStringAsFixed(6)}', style: GoogleFonts.inter(color: const Color(0xFF065F46), fontSize: 12)),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      if (_locationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
                          child: Text(_locationError!, style: GoogleFonts.inter(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation ? null : _fetchLiveLocation,
                          icon: _isLoadingLocation 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.my_location, color: Colors.white, size: 18),
                          label: Text(_isLoadingLocation ? 'Fetching GPS...' : 'Get Current Location', style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              _buildSectionTitle(Icons.edit, 'Description of Violation', Colors.teal),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: GoogleFonts.inter(color: const Color(0xFF1F2937)),
                  decoration: InputDecoration(
                    hintText: 'Enter details (optional)...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text('Submit Challan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFF3F4F6),
                        side: BorderSide.none,
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
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildFileUploader({required File? file, required VoidCallback onTap, required String placeholder, bool isVideo = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isVideo ? 70 : (file == null ? 70 : 220),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5, style: BorderStyle.solid),
        ),
        child: file == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Icon(isVideo ? Icons.videocam : Icons.add_a_photo, color: const Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(placeholder, style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
                ],
              )
            : (isVideo 
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                        child: Text('Browse...', style: GoogleFonts.inter(color: const Color(0xFF374151))),
                      ),
                      Expanded(child: Text(file.path.split('/').last, style: GoogleFonts.inter(color: const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file, fit: BoxFit.cover, width: double.infinity),
                  )
              ),
      ),
    );
  }
}
