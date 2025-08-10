import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  double get progress => targetAmount > 0 ? savedAmount / targetAmount : 0;
  bool get isCompleted => savedAmount >= targetAmount;
}

class SavingsScreen extends StatefulWidget {
  final bool isPremium;
  final PageController? pageController;
  const SavingsScreen({super.key, required this.isPremium, this.pageController});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final List<SavingsGoal> _goals = [];
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  // ignore: unused_field
  String? _error;
  bool _loading = true;

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
    if (mounted) {
      setState(() {
        _goals.clear();
        _goals.addAll((response as List).map((g) => SavingsGoal.fromMap(g)));
        _loading = false;
      });
    }
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

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Goal Name'),
            ),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(labelText: 'Target Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty || _targetController.text.trim().isEmpty) {
                setState(() => _error = 'Please fill in all fields');
                return;
              }
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'target': _targetController.text.trim(),
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final targetAmount = double.tryParse(result['target']!) ?? 0;
      if (targetAmount <= 0) {
        setState(() => _error = 'Please enter a valid amount');
        return;
      }
      await Supabase.instance.client.from('savings_goals').insert({
        'user_id': user.id,
        'name': result['name'],
        'target_amount': targetAmount,
        'saved_amount': 0,
      });
      _nameController.clear();
      _targetController.clear();
      setState(() => _error = null);
      _fetchGoals();
    }
  }

  Future<void> _updateSavedAmount(SavingsGoal goal, double newAmount) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('savings_goals')
        .update({'saved_amount': newAmount})
        .eq('id', goal.id);
    _fetchGoals();
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('savings_goals')
        .delete()
        .eq('id', goal.id);
    _fetchGoals();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalSaved = _goals.fold<double>(0, (sum, g) => sum + g.savedAmount);
    final totalGoals = _goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
    final progress = (totalGoals > 0) ? (totalSaved / totalGoals).clamp(0, 1) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.pageController != null) {
              widget.pageController!.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
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
                                          await _updateSavedAmount(goal, goal.savedAmount + amount);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteGoal(goal),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        child: const Icon(Icons.add),
      ),
    );
  }
} 