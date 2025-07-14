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
      // ignore: unnecessary_null_in_if_null_operators
      _userName = response['name'] ?? null;
      _loading = false;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_userName ?? 'Student'}',
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
                          children: const [
                            Text('Available Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 2),
                            Text('TZS 0.00', style: TextStyle(fontSize: 18)), // Placeholder
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
                            children: const [
                              Icon(Icons.arrow_downward, color: Colors.green),
                              SizedBox(height: 2),
                              Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('TZS 0.00', style: TextStyle(color: Colors.green)), // Placeholder
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        Expanded(
                          child: Column(
                            children: const [
                              Icon(Icons.arrow_upward, color: Colors.red),
                              SizedBox(height: 2),
                              Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('TZS 0.00', style: TextStyle(color: Colors.red)), // Placeholder
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
              child: ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Recent Transactions'),
                subtitle: const Text('No transactions yet.'), // Placeholder
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.pie_chart),
                title: const Text('Budget Summary'),
                subtitle: const Text('No budget set.'), // Placeholder
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
    );
  }
} 