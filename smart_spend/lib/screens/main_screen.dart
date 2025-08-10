import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';
import 'home_screen.dart';
import 'savings_screen.dart';
import 'budget_screen.dart';
import 'tips_screen.dart';
import 'insights_screen.dart';
import '../classes/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<SettingsScreenState> settingsKey = GlobalKey<SettingsScreenState>();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // Initialize screens with the settings key for premium access
    _screens.addAll([
      const HomeScreen(),
      SavingsScreen(isPremium: false, pageController: _pageController), // Will be updated dynamically
      BudgetScreen(isPremium: false, pageController: _pageController), // Will be updated dynamically
      TipsScreen(pageController: _pageController),
      InsightsScreen(pageController: _pageController),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Update premium status for savings and budget screens
  // ignore: unused_element
  void r(bool isPremium) {
    setState(() {
      _screens[1] = SavingsScreen(isPremium: isPremium, pageController: _pageController);
      _screens[2] = BudgetScreen(isPremium: isPremium, pageController: _pageController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
} 