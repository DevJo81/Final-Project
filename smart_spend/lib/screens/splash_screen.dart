import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  void _navigateToNextScreen() {
    // Check if user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.green.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App Name
                  Text(
                    'Smart Spend',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Your personal finance companion for smart spending and saving',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Get Started Button
                  ElevatedButton(
                    onPressed: _navigateToNextScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      // ignore: deprecated_member_use
                      shadowColor: Colors.green.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Subtitle text
                  Text(
                    'Tap to begin your financial journey',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 