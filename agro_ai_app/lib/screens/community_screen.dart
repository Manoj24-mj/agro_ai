import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/service/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  String _userName = "Smart Kisan";
  String _userLocation = "Local Farm";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Smart Kisan";
      // We could also pull actual GPS location here if needed
    });
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Ask the Community", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _postController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "What's happening with your crops? Ask experts...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_postController.text.trim().isEmpty) return;
                  await CommunityService.createPost(
                    authorName: _userName,
                    location: _userLocation,
                    content: _postController.text.trim(),
                  );
                  _postController.clear();
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Post to Krishi Sabha", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              ),
            ),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: CommunityService.getPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading community posts."));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(child: Text("No posts yet. Be the first to ask a question!"));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  
                  return _buildPostCard(
                    docId: docId,
                    name: data['authorName'] ?? "Unknown Farmer",
                    location: data['location'] ?? "Unknown",
                    caption: data['content'] ?? "",
                    likes: data['likes'] ?? 0,
                    aiSuggestion: data['aiSuggestion'],
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard({
    required String docId,
    required String name, 
    required String location, 
    required String caption, 
    required int likes,
    String? aiSuggestion
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.person, color: Colors.green)),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(location, style: const TextStyle(fontSize: 12)),
            ),
            if (aiSuggestion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(aiSuggestion, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(caption, style: const TextStyle(fontSize: 15)),
            ),
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => CommunityService.incrementLike(docId), 
                  icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.grey), 
                  label: Text("$likes", style: const TextStyle(color: Colors.grey))
                ),
                TextButton.icon(
                  onPressed: (){}, 
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey), 
                  label: Text(Lang.t("comment"), style: const TextStyle(color: Colors.grey))
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
