import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Budget'),
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Tips'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Insights'),
      ],
    );
  }
} 