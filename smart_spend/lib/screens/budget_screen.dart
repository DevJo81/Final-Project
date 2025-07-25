import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetCategory {
  String id;
  String category;
  double limit;
  double spent;
  BudgetCategory({required this.id, required this.category, required this.limit, required this.spent});

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'],
      category: map['category'],
      limit: (map['limit_amount'] as num).toDouble(),
      spent: (map['spent_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'limit_amount': limit,
      'spent_amount': spent,
    };
  }
}

class BudgetScreen extends StatefulWidget {
  final bool isPremium;
  const BudgetScreen({super.key, required this.isPremium});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<BudgetCategory> _categories = [];
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  String? _error;
  bool _loading = true;

  int get _selectedIndex => 2;
  void _onNavTap(int index) {
    final routes = ['/home', '/savings', '/budget', '/tips', '/insights'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  bool get _isPremium => widget.isPremium;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final response = await Supabase.instance.client
        .from('budgets')
        .select()
        .eq('user_id', user.id)
        .order('created_at');
    setState(() {
      _categories.clear();
      _categories.addAll((response as List).map((c) => BudgetCategory.fromMap(c)));
      _loading = false;
    });
  }

  Future<void> _addCategory() async {
    if (!_isPremium && _categories.length >= 5) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade Required'),
          content: const Text('Upgrade to Premium to create unlimited budgets.'),
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
    final limit = double.tryParse(_limitController.text.trim());
    if (name.isEmpty || limit == null || limit <= 0) {
      setState(() => _error = 'Enter a valid name and limit.');
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from('budgets')
        .insert({
          'user_id': user.id,
          'category': name,
          'limit_amount': limit,
          'spent_amount': 0,
        })
        .select()
        .single();
    setState(() {
      _categories.add(BudgetCategory.fromMap(response));
      _nameController.clear();
      _limitController.clear();
      _error = null;
    });
  }

  Future<void> _addExpense(int index, double amount) async {
    final cat = _categories[index];
    final newSpent = (cat.spent + amount).clamp(0, cat.limit).toDouble();
    await Supabase.instance.client
        .from('budgets')
        .update({'spent_amount': newSpent})
        .eq('id', cat.id);
    setState(() {
      _categories[index].spent = newSpent;
    });
  }

  Future<void> _editCategory(int index) async {
    final cat = _categories[index];
    final nameController = TextEditingController(text: cat.category);
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
      await Supabase.instance.client
          .from('budgets')
          .update({
            'category': result['name'],
            'limit_amount': result['limit'],
          })
          .eq('id', cat.id);
      setState(() {
        cat.category = result['name'];
        cat.limit = result['limit'];
        if (cat.spent > cat.limit) cat.spent = cat.limit;
      });
    }
  }

  Future<void> _deleteCategory(int index) async {
    final cat = _categories[index];
    await Supabase.instance.client
        .from('budgets')
        .delete()
        .eq('id', cat.id);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                    onPressed: () async => await _addCategory(),
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
                                  title: Text(cat.category),
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
                                                await _addExpense(index, amount);
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