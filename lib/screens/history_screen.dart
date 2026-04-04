import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DatabaseService.getHistory();
    setState(() {
      _history = data;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await DatabaseService.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
               if (_history.isNotEmpty) _clearHistory();
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty 
            ? const Center(child: Text("No scans found in history."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  String sev = item['severity'] ?? "LOW";
                  Color iconColor = Colors.green;
                  IconData icon = Icons.check_circle;
                  
                  if (sev == "HIGH") {
                    iconColor = Colors.redAccent;
                    icon = Icons.warning;
                  } else if (sev == "MEDIUM") {
                    iconColor = Colors.orange;
                    icon = Icons.energy_savings_leaf;
                  }
                  
                  DateTime dt = DateTime.parse(item['timestamp']);
                  String ampm = dt.hour >= 12 ? 'PM' : 'AM';
                  int hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                  String timeStr = "${dt.day}/${dt.month}/${dt.year} - $hr:${dt.minute.toString().padLeft(2, '0')} $ampm";

                  return _buildHistoryItem(icon, item['title'], timeStr, iconColor, item['summary']);
                },
              ),
    );
  }

  Widget _buildHistoryItem(IconData icon, String title, String time, Color color, String subtitle) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {}, // Future tap to reopen full detailed report
      ),
    );
  }
}
