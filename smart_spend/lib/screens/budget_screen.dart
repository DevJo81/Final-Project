import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetCategory {
  String id;
  String category;
  double limit;
  double spent;

  BudgetCategory({
    required this.id, 
    required this.category, 
    required this.limit, 
    required this.spent,
  });

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

  double get remaining => limit - spent;
  double get progress => limit > 0 ? spent / limit : 0;
  bool get isOverBudget => spent > limit;
}

class BudgetScreen extends StatefulWidget {
  final bool isPremium;
  final PageController? pageController;
  const BudgetScreen({super.key, required this.isPremium, this.pageController});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<BudgetCategory> _categories = [];
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  // ignore: unused_field
  String? _error;
  bool _loading = true;

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
    if (mounted) {
      setState(() {
        _categories.clear();
        _categories.addAll((response as List).map((c) => BudgetCategory.fromMap(c)));
        _loading = false;
      });
    }
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

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            TextField(
              controller: _limitController,
              decoration: const InputDecoration(labelText: 'Budget Limit'),
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
              if (_nameController.text.trim().isEmpty || _limitController.text.trim().isEmpty) {
                setState(() => _error = 'Please fill in all fields');
                return;
              }
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'limit': _limitController.text.trim(),
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
      final limit = double.tryParse(result['limit']!) ?? 0;
      if (limit <= 0) {
        setState(() => _error = 'Please enter a valid amount');
        return;
      }
      await Supabase.instance.client.from('budgets').insert({
        'user_id': user.id,
        'category': result['name'],
        'limit_amount': limit,
        'spent_amount': 0,
      });
      _nameController.clear();
      _limitController.clear();
      setState(() => _error = null);
      _fetchCategories();
    }
  }

  Future<void> _updateSpentAmount(BudgetCategory category, double newAmount) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('budgets')
        .update({'spent_amount': newAmount})
        .eq('id', category.id);
    _fetchCategories();
  }

  Future<void> _deleteCategory(BudgetCategory category) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('budgets')
        .delete()
        .eq('id', category.id);
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalBudget = _categories.fold<double>(0, (sum, c) => sum + c.limit);
    final totalSpent = _categories.fold<double>(0, (sum, c) => sum + c.spent);
    final totalRemaining = totalBudget - totalSpent;
    final percentUsed = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0, 1) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
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
                                          await _updateSpentAmount(cat, cat.spent + amount);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteCategory(cat),
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
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
} 