import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';

class VehicleRegistryScreen extends StatefulWidget {
  const VehicleRegistryScreen({super.key});

  @override
  State<VehicleRegistryScreen> createState() => _VehicleRegistryScreenState();
}

class _VehicleRegistryScreenState extends State<VehicleRegistryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final _plateController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _dbService.registerVehicle(
        numberPlate: _plateController.text.trim(),
        ownerName: _nameController.text.trim(),
        ownerEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        ownerPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Vehicle ${_plateController.text.trim().toUpperCase()} registered!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        _plateController.clear();
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteVehicle(String id, String plate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Vehicle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Remove $plate from the registry?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteRegisteredVehicle(id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 20),
            ),
            const SizedBox(width: 10),
            Text('Vehicle Registry', style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Registration Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.app_registration, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Register Vehicle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1F2937))),
                            Text('Link owner contact to vehicle plate', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildFormField(
                      controller: _plateController,
                      label: 'Vehicle Number Plate',
                      hint: 'e.g. KA01HG1234',
                      icon: Icons.confirmation_number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFormField(
                      controller: _nameController,
                      label: 'Owner Full Name',
                      hint: 'e.g. Rahul Sharma',
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFormField(
                      controller: _emailController,
                      label: 'Owner Email',
                      hint: 'e.g. owner@email.com',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    _buildFormField(
                      controller: _phoneController,
                      label: 'Owner Phone',
                      hint: 'e.g. 9876543210',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _registerVehicle,
                          icon: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            _isSubmitting ? 'Registering...' : 'Register Vehicle',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Registered Vehicles List
            Text('Registered Vehicles', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbService.getAllRegisteredVehicles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading vehicles', style: GoogleFonts.inter(color: Colors.red)));
                }

                final vehicles = snapshot.data ?? [];
                if (vehicles.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.directions_car_filled, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No vehicles registered yet', style: GoogleFonts.inter(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final v = vehicles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v['number_plate'] ?? '',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF0F172A), letterSpacing: 1),
                                ),
                                const SizedBox(height: 2),
                                Text(v['owner_name'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
                                if (v['owner_email'] != null && v['owner_email'].toString().isNotEmpty)
                                  Text(v['owner_email'], style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                if (v['owner_phone'] != null && v['owner_phone'].toString().isNotEmpty)
                                  Text(v['owner_phone'], style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteVehicle(v['id'].toString(), v['number_plate']),
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
        hintStyle: GoogleFonts.inter(color: const Color(0xFFD1D5DB), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }
}
