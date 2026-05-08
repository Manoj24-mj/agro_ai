import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/screens/scan_detail_screen.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageHistoryScreen extends StatefulWidget {
  const UsageHistoryScreen({super.key});

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPhone = prefs.getString('userPhone');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userPhone == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Lang.t("usage_history")), backgroundColor: Colors.green[700]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Lang.t("usage_history")),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.document_scanner), text: "Scans"),
              Tab(icon: Icon(Icons.chat), text: "Chats"),
              Tab(icon: Icon(Icons.search), text: "Searches"),
              Tab(icon: Icon(Icons.wb_sunny), text: "Weather"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStreamTab(FirebaseService.getUserScansStream(_userPhone!), _buildScanItem, "scans"),
            _buildStreamTab(FirebaseService.getUserChatsStream(_userPhone!), _buildChatItem, "chats"),
            _buildStreamTab(FirebaseService.getUserSearchesStream(_userPhone!), _buildSearchItem, "searches"),
            _buildStreamTab(FirebaseService.getUserWeatherStream(_userPhone!), _buildWeatherItem, "weather"),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamTab(Stream<QuerySnapshot> stream, Widget Function(Map<String, dynamic>) itemBuilder, String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(Lang.t("history_empty")));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final item = doc.data() as Map<String, dynamic>;
            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                FirebaseService.deleteHistoryItem(
                  phone: _userPhone!,
                  collectionName: collectionName,
                  docId: doc.id,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item deleted from history.")));
              },
              child: itemBuilder(item),
            );
          },
        );
      },
    );
  }

  Widget _buildScanItem(Map<String, dynamic> item) {
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
    
    return _buildHistoryCard(
      icon: icon,
      color: iconColor,
      title: item['title'] ?? Lang.t("plant_scan"),
      badgeText: "SCAN",
      subtitle: item['result'] ?? Lang.t("no_summary"),
      timestamp: item['timestamp'],
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanDetailScreen(item: item)));
      },
    );
  }

  Widget _buildChatItem(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.chat_bubble_outline,
      color: Colors.blue,
      title: item['query'] ?? "Chat",
      badgeText: "CHAT",
      subtitle: item['reply'] ?? "",
      timestamp: item['timestamp'],
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                const Text("AI Chat Details"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("You asked:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 4),
                  Text("${item['query'] ?? 'Unknown'}", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  const Text("Smart Kisan AI replied:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text("${item['reply'] ?? 'Unknown'}", style: const TextStyle(fontSize: 15)),
                  if (item['timestamp'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      "${(item['timestamp'] as Timestamp).toDate().toString().split('.').first}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchItem(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.search,
      color: Colors.purple,
      title: item['query'] ?? "Search",
      badgeText: item['category'] ?? "SEARCH",
      subtitle: "Searched in ${item['category'] ?? 'App'}",
      timestamp: item['timestamp'],
    );
  }

  Widget _buildWeatherItem(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.wb_sunny,
      color: Colors.orange,
      title: item['location'] ?? "Weather",
      badgeText: "WEATHER",
      subtitle: "${item['condition'] ?? ''} - ${item['temperature']}°C",
      timestamp: item['timestamp'],
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange),
                const SizedBox(width: 8),
                Text(item['location'] ?? "Weather details"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Condition: ${item['condition'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Temperature: ${item['temperature']}°C", style: const TextStyle(fontSize: 16)),
                if (item['timestamp'] != null) ...[
                  const SizedBox(height: 16),
                  Text("Checked on:", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    "${(item['timestamp'] as Timestamp).toDate().toString().split('.').first}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String badgeText,
    required String subtitle,
    required dynamic timestamp,
    VoidCallback? onTap,
  }) {
    String timeStr = "Unknown Time";
    if (timestamp != null) {
      DateTime dt = (timestamp as Timestamp).toDate();
      timeStr = "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(badgeText, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey) : null,
        onTap: onTap,
      ),
    );
  }
}
