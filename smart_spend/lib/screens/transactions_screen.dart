import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _transactions = [];
        _totalIncome = 0;
        _totalExpense = 0;
        _loading = false;
      });
      return;
    }
    final response = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false);
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
      _transactions = txs;
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
      _loading = false;
    });
  }

  Future<void> _addTransaction(BuildContext context, String type) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${type == 'income' ? 'Income' : 'Expense'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      final amount = double.tryParse(amountController.text.trim());
      if (amount == null || amount <= 0) return;
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'type': type,
        'amount': amount,
        'category': categoryController.text.trim(),
        'description': descriptionController.text.trim(),
      });
      _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Income',
            onPressed: () => _addTransaction(context, 'income'),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Add Expense',
            onPressed: () => _addTransaction(context, 'expense'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('TZS ${_totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('TZS ${_totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Savings', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('TZS ${(_totalIncome - _totalExpense).toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text('No transactions yet.'))
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
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
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 