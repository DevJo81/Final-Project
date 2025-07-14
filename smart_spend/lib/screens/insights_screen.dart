import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  int get _selectedIndex => 4;
  void _onNavTap(BuildContext context, int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Example values
    final double totalBudget = 100000;
    final double spent = 65000;
    final double remaining = totalBudget - spent;
    final double percentUsed = spent / totalBudget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: percentUsed,
                    strokeWidth: 18,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentUsed < 0.7
                          ? Colors.green
                          : (percentUsed < 0.9 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    Text(
                      'TZS ${remaining.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Total Budget: TZS ${totalBudget.toStringAsFixed(0)}'),
            Text('Spent: TZS ${spent.toStringAsFixed(0)}'),
            Text('Remaining: TZS ${remaining.toStringAsFixed(0)}'),
            const SizedBox(height: 24),
            Text(
              percentUsed < 0.7
                  ? 'You are on track with your spending!'
                  : (percentUsed < 0.9
                      ? 'Caution: You have used most of your budget.'
                      : 'Warning: You are about to exceed your budget!'),
              style: TextStyle(
                color: percentUsed < 0.7
                    ? Colors.green
                    : (percentUsed < 0.9 ? Colors.orange : Colors.red),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
} 