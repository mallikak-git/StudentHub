import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const List<String> kCategories = ['Food', 'Transport', 'Books', 'Entertainment', 'Health', 'Other'];
const List<Color> kCategoryColors = [
  Color(0xFFFF6584), Color(0xFF6C63FF), Color(0xFF43E97B),
  Color(0xFFF7971E), Color(0xFF38B2FF), Color(0xFFA0A0C0),
];

class Transaction {
  String id, desc, category;
  double amount;
  bool isIncome;
  DateTime date;

  Transaction({required this.id, required this.desc, required this.category,
    required this.amount, required this.isIncome, required this.date});

  Map<String, dynamic> toJson() => {
    'id': id, 'desc': desc, 'category': category,
    'amount': amount, 'isIncome': isIncome, 'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id: j['id'], desc: j['desc'], category: j['category'],
    amount: j['amount'], isIncome: j['isIncome'], date: DateTime.parse(j['date']),
  );
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('transactions_v2');
    if (data != null) {
      setState(() {
        _transactions = (json.decode(data) as List).map((e) => Transaction.fromJson(e)).toList();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('transactions_v2', json.encode(_transactions.map((t) => t.toJson()).toList()));
  }

  double get _totalIncome => _transactions.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _totalExpense => _transactions.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _balance => _totalIncome - _totalExpense;

  
  void _showAddSheet(bool defaultIncome) {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Food';
    bool isIncome = defaultIncome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Income / Expense toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => isIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isIncome ? const Color(0xFF43E97B) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text('+ Income', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.white : Colors.grey,
                        )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => isIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isIncome ? const Color(0xFFFF6584) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text('- Expense', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !isIncome ? Colors.white : Colors.grey,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              if (!isIncome)
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: kCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setSheet(() => category = v!),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amtCtrl.text);
                    if (amt == null || amt <= 0 || descCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _transactions.insert(0, Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        desc: descCtrl.text.trim(),
                        category: isIncome ? 'Income' : category,
                        amount: amt,
                        isIncome: isIncome,
                        date: DateTime.now(),
                      ));
                    });
                    _save();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Budget'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Transactions')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildOverview(), _buildTransactions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(false),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF)..withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '₹${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BalanceTile(label: 'Income', amount: _totalIncome, color: const Color(0xFF43E97B), icon: Icons.arrow_downward),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _BalanceTile(label: 'Expenses', amount: _totalExpense, color: const Color(0xFFFF6584), icon: Icons.arrow_upward),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Category breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spending by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  ...List.generate(kCategories.length, (i) {
                    final cat = kCategories[i];
                    final total = _transactions.where((t) => !t.isIncome && t.category == cat).fold(0.0, (s, t) => s + t.amount);
                    if (total == 0) return const SizedBox.shrink();
                    final pct = _totalExpense > 0 ? total / _totalExpense : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: kCategoryColors[i], shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(cat, style: const TextStyle(fontSize: 13)),
                              const Spacer(),
                              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              color: kCategoryColors[i],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_totalExpense == 0)
                    Center(child: Text('No expenses yet', style: TextStyle(color: Colors.grey[500]))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No transactions yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _transactions.length,
      itemBuilder: (_, i) {
        final t = _transactions[i];
        final catIdx = kCategories.indexOf(t.category);
        final color = t.isIncome ? const Color(0xFF43E97B) : (catIdx >= 0 ? kCategoryColors[catIdx] : Colors.grey);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha:0.15),
              child: Icon(t.isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
            ),
            title: Text(t.desc, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${t.category} · ${t.date.day}/${t.date.month}/${t.date.year}',
                style: const TextStyle(fontSize: 12)),
            trailing: Text(
              '${t.isIncome ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        );
      },
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _BalanceTile({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
