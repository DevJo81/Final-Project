import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';

class SavingsGoal {
  final String name;
  final double targetAmount;
  double savedAmount;
  SavingsGoal({required this.name, required this.targetAmount, this.savedAmount = 0});
}

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final List<SavingsGoal> _goals = [];
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String? _error;

  int get _selectedIndex => 1;
  void _onNavTap(int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  void _addGoal() {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    if (name.isEmpty || target == null || target <= 0) {
      setState(() => _error = 'Enter a valid name and target amount.');
      return;
    }
    setState(() {
      _goals.add(SavingsGoal(name: name, targetAmount: target));
      _nameController.clear();
      _targetController.clear();
      _error = null;
    });
  }

  void _addToGoal(int index, double amount) {
    setState(() {
      _goals[index].savedAmount += amount;
      if (_goals[index].savedAmount > _goals[index].targetAmount) {
        _goals[index].savedAmount = _goals[index].targetAmount;
      }
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
      body: Padding(
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
              onPressed: _addGoal,
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
                                          _addToGoal(index, amount);
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