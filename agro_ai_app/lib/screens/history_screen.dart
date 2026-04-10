import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/database_service.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/screens/scan_detail_screen.dart';

class UsageHistoryScreen extends StatefulWidget {
  const UsageHistoryScreen({super.key});

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
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
        title: Text(Lang.t("usage_history")),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: "Clear Local Logs",
            onPressed: () {
               if (_history.isNotEmpty) _clearHistory();
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty 
            ? Center(child: Text(Lang.t("history_empty")))
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
                  String timeStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                  
                  bool isChat = item['type'] == 'chat';

                  return _buildHistoryItem(
                    context,
                    item,
                    isChat ? Icons.chat_bubble_outline : icon, 
                    isChat ? Lang.t("chat_with_ai") : (item['title'] != null ? item['title'] : Lang.t("plant_scan")), 
                    timeStr, 
                    isChat ? Colors.blue : iconColor, 
                    item['summary'] ?? Lang.t("no_summary"),
                    isChat: isChat,
                  );
                },
              ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item, IconData icon, String title, String time, Color color, String subtitle, {bool isChat = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isChat) 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: const Text("CHAT", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
              )
            else
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                child: const Text("SCAN", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanDetailScreen(item: item),
            ),
          );
        }, 
      ),
    );
  }
}
