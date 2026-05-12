import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Map<String, dynamic>> _transactions = [];
  double _balance = 0.0;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _type = 'Expense';

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('farmer_ledger');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _transactions = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    _calculateBalance();
  }

  void _calculateBalance() {
    double bal = 0;
    for (var t in _transactions) {
      if (t['type'] == 'Income') {
        bal += t['amount'];
      } else {
        bal -= t['amount'];
      }
    }
    setState(() {
      _balance = bal;
    });
  }

  Future<void> _addTransaction() async {
    if (_amountController.text.isEmpty || _descController.text.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final transaction = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': _type,
      'amount': double.parse(_amountController.text),
      'desc': _descController.text,
      'date': DateTime.now().toIso8601String(),
    };
    
    setState(() {
      _transactions.insert(0, transaction);
      _amountController.clear();
      _descController.clear();
      _calculateBalance();
    });
    
    await prefs.setString('farmer_ledger', jsonEncode(_transactions));
    Navigator.pop(context); // Close bottom sheet
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Add Transaction", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Expense', label: Text('Expense (Red)')),
                    ButtonSegment(value: 'Income', label: Text('Income (Green)')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<String> newSelection) {
                    setModalState(() {
                      _type = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description (e.g. Seeds, Sold Wheat)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _addTransaction();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("Save Record", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Farmer's Ledger (Khata)", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        backgroundColor: Colors.green[800],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Record", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  "₹${_balance.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _balance < 0 ? Colors.redAccent : Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
              ? const Center(child: Text("No records yet. Add an expense or income!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final t = _transactions[index];
                    final isExpense = t['type'] == 'Expense';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: isExpense ? Colors.red : Colors.green),
                        ),
                        title: Text(t['desc'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(t['date']))),
                        trailing: Text(
                          "${isExpense ? '-' : '+'}₹${t['amount']}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isExpense ? Colors.red : Colors.green),
                        ),
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
