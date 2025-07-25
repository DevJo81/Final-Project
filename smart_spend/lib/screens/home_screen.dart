import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  bool _loading = true;
  int _selectedIndex = 0;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double get _totalSavings => _totalIncome - _totalExpense;

  List<Map<String, dynamic>> _recentTransactions = [];
  double _budgetTotal = 0;
  double _budgetSpent = 0;
  double _budgetRemaining = 0;
  double _budgetPercentUsed = 0;
  bool _budgetLoading = true;
  bool _transactionsLoading = true;

  final List<String> _routes = [
    '/home',
    '/savings',
    '/budget',
    '/tips',
    '/insights',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchTransactionSummary();
    _fetchRecentTransactions();
    _fetchBudgetSummary();
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .single();
    setState(() {
      _userName = response['name'];
      _loading = false;
    });
  }

  Future<void> _fetchTransactionSummary() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', user.id);
    final txs = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final totalIncome = txs
        .where((t) => t['type'] == 'income')
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());
    final totalExpense = txs
        .where((t) => t['type'] == 'expense')
        .fold<double>(0, (sum, t) => sum + (t['amount'] as num).toDouble());
    setState(() {
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
    });
  }

  Future<void> _fetchRecentTransactions() async {
    setState(() => _transactionsLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _recentTransactions = [];
        _transactionsLoading = false;
      });
      return;
    }
    final response = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .limit(3);
    final txs = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    setState(() {
      _recentTransactions = txs;
      _transactionsLoading = false;
    });
  }

  Future<void> _fetchBudgetSummary() async {
    setState(() => _budgetLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _budgetTotal = 0;
        _budgetSpent = 0;
        _budgetRemaining = 0;
        _budgetPercentUsed = 0;
        _budgetLoading = false;
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
    final totalRemaining = totalBudget - totalSpent;
    final percentUsed = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1) : 0.0;
    setState(() {
      _budgetTotal = totalBudget;
      _budgetSpent = totalSpent;
      _budgetRemaining = totalRemaining;
      _budgetPercentUsed = percentUsed.toDouble();
      _budgetLoading = false;
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_routes[index] != '/home') {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // ignore: unused_local_variable
    final user = Supabase.instance.client.auth.currentUser;

    // Determine greeting based on time of day
    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good morning';
      } else if (hour < 17) {
        return 'Good afternoon';
      } else {
        return 'Good evening';
      }
    }

    final greeting = getGreeting();
    final displayName = _userName ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Spend', textAlign: TextAlign.center),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ' $greeting, $displayName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Let's manage your finances",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 32),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Available Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('TZS ${_totalSavings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(Icons.arrow_downward, color: Colors.green),
                                    const SizedBox(height: 2),
                                    const Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('TZS ${_totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 40, color: Colors.grey[300]),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(Icons.arrow_upward, color: Colors.red),
                                    const SizedBox(height: 2),
                                    const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('TZS ${_totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.trending_up),
                              SizedBox(width: 8),
                              Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _transactionsLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _recentTransactions.isEmpty
                                  ? const Text('No transactions yet.')
                                  : Column(
                                      children: _recentTransactions.map((tx) {
                                        final isIncome = tx['type'] == 'income';
                                        return ListTile(
                                          leading: Icon(isIncome ? Icons.add : Icons.remove, color: isIncome ? Colors.green : Colors.red),
                                          title: Text('${tx['category'] ?? ''}'),
                                          subtitle: Text('${tx['description'] ?? ''}\n${tx['date'] != null ? DateTime.parse(tx['date']).toLocal().toString().substring(0, 16) : ''}'),
                                          trailing: Text(
                                            'TZS ${(tx['amount'] as num).toStringAsFixed(2)}',
                                            style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.pie_chart),
                              SizedBox(width: 8),
                              Text('Budget Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _budgetLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _budgetTotal == 0
                                  ? const Text('No budget set.')
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Budget: TZS ${_budgetTotal.toStringAsFixed(2)}'),
                                        Text('Total Spent: TZS ${_budgetSpent.toStringAsFixed(2)}'),
                                        Text('Total Remaining: TZS ${_budgetRemaining.toStringAsFixed(2)}'),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(value: _budgetPercentUsed),
                                        const SizedBox(height: 4),
                                        Text('Percent Used: ${(_budgetPercentUsed * 100).toStringAsFixed(1)}%'),
                                      ],
                                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions'),
        tooltip: 'Transactions',
        child: const Icon(Icons.swap_horiz),
      ),
    );
  }
} 