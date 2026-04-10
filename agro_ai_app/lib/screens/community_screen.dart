import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(Lang.t("comm_title")),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background floating particle effect (simulated with gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              ),
            ),
          ),
          
          ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildPostCard(
                name: ["Ravi Kumar", "Anita Desai", "Suresh Patel"][index],
                location: ["Punjab, India", "Gujarat, India", "Maharashtra, India"][index],
                caption: [
                  "My wheat crops are showing these yellow spots. Any advice?",
                  "Successfully harvested my tomatoes today! Great yield.",
                  "What is the best organic pesticide for aphids?"
                ][index],
                aiSuggestion: index == 0 ? "AI thinks this might be Yellow Rust" : null,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard({required String name, required String location, required String caption, String? aiSuggestion}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.person, color: Colors.green)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(location, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.more_vert),
              ),
              // Image Placeholder
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.green.shade50,
                child: const Icon(Icons.eco, size: 80, color: Colors.white), // Mock Image
              ),
              // AI Banner
              if (aiSuggestion != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.amber.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(aiSuggestion, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              // Caption
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(caption, style: const TextStyle(fontSize: 14)),
              ),
              // Actions
              const Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(onPressed: (){}, icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.grey), label: Text(Lang.t("like"), style: const TextStyle(color: Colors.grey))),
                  TextButton.icon(onPressed: (){}, icon: const Icon(Icons.comment_outlined, color: Colors.grey), label: Text(Lang.t("comment"), style: const TextStyle(color: Colors.grey))),
                  TextButton.icon(onPressed: (){}, icon: const Icon(Icons.share_outlined, color: Colors.grey), label: Text(Lang.t("share"), style: const TextStyle(color: Colors.grey))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
