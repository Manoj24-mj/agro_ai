import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'krishi_sabha_posts';

  // Get stream of all posts, ordered by newest first
  static Stream<QuerySnapshot> getPostsStream() {
    return _db.collection(_collection).orderBy('timestamp', descending: true).snapshots();
  }

  // Create a new post
  static Future<void> createPost({
    required String authorName,
    required String location,
    required String content,
    String? aiSuggestion,
  }) async {
    await _db.collection(_collection).add({
      'authorName': authorName,
      'location': location,
      'content': content,
      'aiSuggestion': aiSuggestion,
      'likes': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Like a post
  static Future<void> incrementLike(String postId) async {
    await _db.collection(_collection).doc(postId).update({
      'likes': FieldValue.increment(1),
    });
  }
}
