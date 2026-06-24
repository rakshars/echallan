import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'citizen_dashboard.dart';
import 'police_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'Citizen';
  final List<String> _roles = ['Citizen', 'Police Officer'];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          role: _selectedRole,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful!')),
          );

          final user = response.user;
          final role = user?.userMetadata?['role'] ?? _selectedRole;

          // Create user profile for leaderboard
          if (user != null) {
            _dbService.upsertUserProfile(
              userId: user.id,
              fullName: _nameController.text.trim(),
              role: _selectedRole,
            );
          }

          if (role == 'Police Officer') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PoliceDashboard()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CitizenDashboard()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        height: 80,
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 140),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_moon_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ).animate().fade().scale(),
                      const SizedBox(height: 32),
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A),
                          letterSpacing: 0.5,
                        ),
                      ).animate().fade().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'Join CitiWatch to impact road safety',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF4B5563),
                        ),
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 48),
                      
                      _buildTextField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                      ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      
                      _buildTextField(
                        label: 'Email Address',
                        icon: Icons.alternate_email,
                        controller: _emailController,
                      ).animate().fade(delay: 300.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      
                      _buildDropdown().animate().fade(delay: 400.ms).slideX(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      
                      _buildTextField(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                      ).animate().fade(delay: 500.ms).slideX(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'REGISTER',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ).animate().fade(delay: 600.ms).scale(),
                      
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: GoogleFonts.inter(color: const Color(0xFF4B5563)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Login',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 700.ms),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1
          ),
        ]
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? (label.contains('Email') ? TextInputType.emailAddress : TextInputType.text),
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
          prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1
          ),
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
        style: GoogleFonts.inter(color: const Color(0xFF111827), fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Role',
          labelStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF3B82F6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: _roles.map((String role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(role),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedRole = newValue;
            });
          }
        },
      ),
    );
  }
}
