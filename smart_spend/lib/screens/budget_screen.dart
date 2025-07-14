import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';

class BudgetCategory {
  String name;
  double limit;
  double spent;
  BudgetCategory({required this.name, required this.limit, this.spent = 0});
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<BudgetCategory> _categories = [];
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  String? _error;

  int get _selectedIndex => 2;
  void _onNavTap(int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  void _addCategory() {
    final name = _nameController.text.trim();
    final limit = double.tryParse(_limitController.text.trim());
    if (name.isEmpty || limit == null || limit <= 0) {
      setState(() => _error = 'Enter a valid name and limit.');
      return;
    }
    setState(() {
      _categories.add(BudgetCategory(name: name, limit: limit));
      _nameController.clear();
      _limitController.clear();
      _error = null;
    });
  }

  void _addExpense(int index, double amount) {
    setState(() {
      _categories[index].spent += amount;
      if (_categories[index].spent > _categories[index].limit) {
        _categories[index].spent = _categories[index].limit;
      }
    });
  }

  void _editCategory(int index) async {
    final cat = _categories[index];
    final nameController = TextEditingController(text: cat.name);
    final limitController = TextEditingController(text: cat.limit.toStringAsFixed(2));
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(labelText: 'Monthly Limit (TZS)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newLimit = double.tryParse(limitController.text.trim());
                if (newName.isNotEmpty && newLimit != null && newLimit > 0) {
                  Navigator.of(context).pop({'name': newName, 'limit': newLimit});
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        cat.name = result['name'];
        cat.limit = result['limit'];
        if (cat.spent > cat.limit) cat.spent = cat.limit;
      });
    }
  }

  void _deleteCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _categories.fold<double>(0, (sum, c) => sum + c.limit);
    final totalSpent = _categories.fold<double>(0, (sum, c) => sum + c.spent);
    final totalRemaining = totalBudget - totalSpent;
    final percentUsed = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1) : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
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
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Budget: TZS ${totalBudget.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Spent: TZS ${totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Remaining: TZS ${totalRemaining.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: percentUsed.toDouble()),
                    const SizedBox(height: 4),
                    Text('Percent Used: ${(percentUsed * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _limitController,
              decoration: const InputDecoration(labelText: 'Monthly Limit (TZS)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Add Category'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _categories.isEmpty
                  ? const Center(child: Text('No budget categories yet.'))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final progress = cat.spent / cat.limit;
                        final percent = (progress * 100).clamp(0, 999).toStringAsFixed(1);
                        final overBudget = cat.spent > cat.limit;
                        return Card(
                          child: ListTile(
                            title: Text(cat.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Limit: TZS ${cat.limit.toStringAsFixed(2)}'),
                                Text('Spent: TZS ${cat.spent.toStringAsFixed(2)}'),
                                Text('Remaining: TZS ${(cat.limit - cat.spent).toStringAsFixed(2)}'),
                                LinearProgressIndicator(value: progress.toDouble()),
                                Row(
                                  children: [
                                    Text(
                                      '$percent% used',
                                      style: TextStyle(
                                        color: overBudget ? Colors.red : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      overBudget ? 'Over Budget' : 'Within Budget',
                                      style: TextStyle(
                                        color: overBudget ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () async {
                                        final amount = await showDialog<double>(
                                          context: context,
                                          builder: (context) {
                                            final controller = TextEditingController();
                                            return AlertDialog(
                                              title: const Text('Log Expense'),
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
                                          _addExpense(index, amount);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editCategory(index),
                                      tooltip: 'Edit Category',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteCategory(index),
                                      tooltip: 'Delete Category',
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