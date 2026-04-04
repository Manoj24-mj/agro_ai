import 'package:flutter/material.dart';

class UserActivityScreen extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<Map<String, String>> items;

  const UserActivityScreen({
    super.key, 
    required this.title, 
    required this.emptyMessage, 
    required this.items
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: items.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: ListTile(
                    title: Text(item['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['subtitle'] ?? ""),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {},
                  ),
                );
              },
            ),
    );
  }
}
