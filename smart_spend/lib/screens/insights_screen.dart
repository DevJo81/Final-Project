import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bottom_nav.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  double? _totalBudget;
  double? _totalSpent;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBudgetStats();
  }

  Future<void> _fetchBudgetStats() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _totalBudget = 0;
        _totalSpent = 0;
        _loading = false;
      });
      return;
    }
    final response = await Supabase.instance.client
        .from('budgets')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    final categories = (response as List)
        .map((c) => {
              'limit': (c['limit_amount'] as num).toDouble(),
              'spent': (c['spent_amount'] as num).toDouble(),
            })
        .toList();
    final totalBudget = categories.fold<double>(0, (sum, c) => sum + c['limit']!);
    final totalSpent = categories.fold<double>(0, (sum, c) => sum + c['spent']!);
    setState(() {
      _totalBudget = totalBudget;
      _totalSpent = totalSpent;
      _loading = false;
    });
  }

  Future<Map<String, double>> _getCategorySpend() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    final response = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', user.id);

    final txs = (response as List).map((e) => Map<String, dynamic>.from(e)).toList();

    Map<String, double> totals = {};
    for (var tx in txs) {
      if (tx['type'] == 'expense') {
        final category = tx['category'] ?? 'Other';
        totals[category] = (totals[category] ?? 0) + (tx['amount'] as num).toDouble();
      }
    }
    return totals;
  }

  int get _selectedIndex => 4;
  void _onNavTap(BuildContext context, int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final double totalBudget = _totalBudget ?? 0;
    final double spent = _totalSpent ?? 0;
    final double remaining = totalBudget - spent;
    final double percentUsed = totalBudget > 0 ? (spent / totalBudget).clamp(0, 1) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 24),
              Text('Total Budget: TZS ${totalBudget.toStringAsFixed(0)}'),
              Text('Spent: TZS ${spent.toStringAsFixed(0)}'),
              Text('Remaining: TZS ${remaining.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              const Text(
                'Expenses by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, double>>(
                future: _getCategorySpend(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No spending data found.');
                  }

                  final data = snapshot.data!;
                  final sections = data.entries.map((e) {
                    return PieChartSectionData(
                      value: e.value,
                      title: e.key,
                      color: Colors.primaries[
                        data.keys.toList().indexOf(e.key) % Colors.primaries.length],
                      radius: 40,
                    );
                  }).toList();

                  return SizedBox(
                    height: 240,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => _onNavTap(context, index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions'),
        tooltip: 'Transactions',
        child: const Icon(Icons.swap_horiz),
      ),
    );
  }
} 