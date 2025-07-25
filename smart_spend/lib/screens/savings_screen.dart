import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double savedAmount;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
  });

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
    };
  }
}

class SavingsScreen extends StatefulWidget {
  final bool isPremium;
  const SavingsScreen({super.key, required this.isPremium});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final List<SavingsGoal> _goals = [];
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String? _error;
  bool _loading = true;

  int get _selectedIndex => 1;
  void _onNavTap(int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  bool get _isPremium => widget.isPremium;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final response = await Supabase.instance.client
        .from('savings_goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    setState(() {
      _goals.clear();
      _goals.addAll((response as List).map((g) => SavingsGoal.fromMap(g)));
      _loading = false;
    });
  }

  Future<void> _addGoal() async {
    if (!_isPremium && _goals.length >= 5) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade Required'),
          content: const Text('Upgrade to Premium to create unlimited savings goals.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/settings');
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    if (name.isEmpty || target == null || target <= 0) {
      setState(() => _error = 'Enter a valid name and target amount.');
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from('savings_goals')
        .insert({
          'user_id': user.id,
          'name': name,
          'target_amount': target,
          'saved_amount': 0,
        })
        .select()
        .single();
    setState(() {
      _goals.add(SavingsGoal.fromMap(response));
      _nameController.clear();
      _targetController.clear();
      _error = null;
    });
  }

  Future<void> _addToGoal(int index, double amount) async {
    final goal = _goals[index];
    final newSaved = (goal.savedAmount + amount).clamp(0, goal.targetAmount).toDouble();
    await Supabase.instance.client
        .from('savings_goals')
        .update({'saved_amount': newSaved})
        .eq('id', goal.id);
    setState(() {
      _goals[index].savedAmount = newSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSaved = _goals.fold<double>(0, (sum, g) => sum + g.savedAmount);
    final totalGoals = _goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final progress = (totalGoals > 0) ? (totalSaved / totalGoals).clamp(0, 1) : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Saved: TZS ${totalSaved.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Total Goals: TZS ${totalGoals.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: progress.toDouble()),
                          const SizedBox(height: 4),
                          Text('Overall Progress: ${(progress * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Goal Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetController,
                    decoration: const InputDecoration(labelText: 'Target Amount (TZS)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () async => await _addGoal(),
                    child: const Text('Add Goal'),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _goals.isEmpty
                        ? const Center(child: Text('No savings goals yet.'))
                        : ListView.builder(
                            itemCount: _goals.length,
                            itemBuilder: (context, index) {
                              final goal = _goals[index];
                              final progress = goal.savedAmount / goal.targetAmount;
                              return Card(
                                child: ListTile(
                                  title: Text(goal.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Saved: TZS ${goal.savedAmount.toStringAsFixed(2)} / TZS ${goal.targetAmount.toStringAsFixed(2)}'),
                                      LinearProgressIndicator(value: progress.toDouble()),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () async {
                                              final amount = await showDialog<double>(
                                                context: context,
                                                builder: (context) {
                                                  final controller = TextEditingController();
                                                  return AlertDialog(
                                                    title: const Text('Add to Savings'),
                                                    content: TextField(
                                                      controller: controller,
                                                      decoration: const InputDecoration(labelText: 'Amount (TZS)'),
                                                      keyboardType: TextInputType.number,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          final value = double.tryParse(controller.text.trim());
                                                          if (value != null && value > 0) {
                                                            Navigator.of(context).pop(value);
                                                          }
                                                        },
                                                        child: const Text('Add'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              if (amount != null && amount > 0) {
                                                await _addToGoal(index, amount);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
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