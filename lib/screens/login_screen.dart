import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../core/constants/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lightPrimary,
                  AppColors.lightSecondary,
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
              duration: 3.seconds,
              color: Colors.white.withValues(alpha: 0.2),
              angle: 45),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mascot / Logo
                      Container(
                        width: 160,
                        height: 160,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/mascot.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets_rounded,
                              size: 80,
                              color: AppColors.lightPrimary,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .then()
                          .moveY(
                              begin: 0,
                              end: -10,
                              duration: 2.seconds,
                              curve: Curves.easeInOut)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                              begin: 0,
                              end: -10,
                              duration: 2.seconds,
                              curve: Curves.easeInOut),

                      const SizedBox(height: 40),

                      // Title & Subtitle
                      Column(
                        children: [
                          const Text(
                            'Cute Todo',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).moveY(begin: 20),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Make productivity fun! ✨',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .scale(duration: 400.ms),
                        ],
                      ),

                      const SizedBox(height: 80),

                      // Login Button
                      if (_isLoading)
                        const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.network(
                              'https://www.google.com/favicon.ico',
                              height: 18,
                              width: 18,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.login,
                                size: 18,
                              ),
                            ),
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.lightPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0, // Flat modern look,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms)
                            .moveY(begin: 40, duration: 500.ms)
                            .shimmer(delay: 1500.ms, duration: 1.seconds),

                      const SizedBox(height: 24),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
