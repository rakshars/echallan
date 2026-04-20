import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'citizen_dashboard.dart';
import 'police_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for exactly 2.5 seconds to show the animation
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;

    final user = _authService.getCurrentUser();
    
    // Auto-login routing logic
    if (user != null) {
      final role = user.userMetadata?['role'] ?? 'Citizen';
      if (role == 'Police Officer') {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PoliceDashboard(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CitizenDashboard(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else {
      // Not logged in, go to Login Screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_moon_rounded,
                size: 60,
                color: Colors.white,
              ),
            ).animate()
              .scale(duration: 800.ms, curve: Curves.easeOutBack)
              .shimmer(delay: 800.ms, duration: 1000.ms)
              .boxShadow(
                begin: BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0), blurRadius: 0),
                end: BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15)),
                duration: 600.ms
              ),
            
            const SizedBox(height: 32),
            
            Text(
              'CitiWatch',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E3A8A),
                letterSpacing: 1.0,
              ),
            ).animate()
              .fade(duration: 600.ms, delay: 300.ms)
              .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
              
            const SizedBox(height: 12),
            
            Text(
              'Empowering Citizens. Securing Roads.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ).animate()
              .fade(duration: 600.ms, delay: 500.ms)
              .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
