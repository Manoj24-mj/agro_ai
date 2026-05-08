import 'package:flutter/material.dart';
import 'package:agro_ai_app/service/voice_service.dart';

import 'package:agro_ai_app/service/database_service.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:agro_ai_app/service/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:agro_ai_app/service/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<EdgeChat> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  final GeminiService _geminiService = GeminiService();

  bool _isListening = false;
  bool _isVoiceEnabled = false; // Default to OFF to respect user's request for manual control

  @override
  void initState() {
    super.initState();
    _loadMessages();
    Lang().addListener(_onLangChanged);
  }

  void _onLangChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    Lang().removeListener(_onLangChanged);
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (kIsWeb) {
      setState(() {
        _messages.add(EdgeChat(
          user: "Bot", 
          message: Lang.t("chatbot_welcome"), 
          isUser: false
        ));
      });
      return;
    }
    
    final saved = await DatabaseService.getMessages();
    setState(() {
      if (saved.isEmpty) {
        _messages.add(EdgeChat(
          user: "Bot", 
          message: Lang.t("chatbot_welcome"), 
          isUser: false
        ));
      } else {
        for (var m in saved) {
          _messages.add(EdgeChat(
            user: m['user'],
            message: m['message'],
            isUser: m['isUser'] == 1,
          ));
        }
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> send(String msg) async {
    if (msg.trim().isEmpty) return;
    
    setState(() {
      _messages.add(EdgeChat(user: "You", message: msg, isUser: true));
      _messages.add(EdgeChat(user: "Bot", message: Lang.t("thinking"), isUser: false));
    });
    _scrollToBottom();
    _controller.clear();
    
    if (!kIsWeb) await DatabaseService.saveMessage("You", msg, true);

    try {
      final reply = await _geminiService.askGemini(msg, languageCode: Lang.lang);

      setState(() {
        _messages.removeLast();
        _messages.add(EdgeChat(user: "Bot", message: reply, isUser: false));
      });
      
      // Save to Local History AND Firebase
      if (!kIsWeb) {
        await DatabaseService.saveMessage("Bot", reply, false);
      }
      
      await DatabaseService.saveHistory(
        "AI Conversation", 
        msg, 
        reply, 
        "LOW", 
        type: 'chat'
      );

      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('userPhone');
      if (phone != null) {
        await FirebaseService.saveChatMessage(
          phone: phone,
          message: msg,
          reply: reply,
        );
      }
          // (Automatic Cloud upload removed. Manual save button added below instead.)
      
      if (_isVoiceEnabled) _voiceService.speak(reply); // Conditional Voice Output
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(EdgeChat(user: "Bot", message: "Error: ${e.toString()}", isUser: false));
      });
    }
    _scrollToBottom();
  }

  void toggleListening() {
    if (_isListening) {
      _voiceService.speech.stop();
      setState(() => _isListening = false);
    } else {
      _voiceService.startListening((text) {
        _controller.text = text;
        if (text.isNotEmpty) {
           setState(() => _isListening = false);
           send(text);
        }
      });
      setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Text(Lang.t("title")),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isVoiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _isVoiceEnabled = !_isVoiceEnabled;
                if (!_isVoiceEnabled) {
                  _voiceService.stop();
                }
              });
            },
            tooltip: "Toggle Auto-Speech",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];
                return _ChatBubble(
                  message: chat.message,
                  isUser: chat.isUser,
                  onVoice: () => _voiceService.speak(chat.message),
                  onSave: chat.isUser || chat.message == Lang.t("thinking") ? null : () async {
                     final prefs = await SharedPreferences.getInstance();
                     final phone = prefs.getString('userPhone') ?? "Anonymous";
                     
                     try {
                        await FirebaseService.saveChatMessage(
                          phone: phone,
                          message: "AI Guidance",
                          reply: chat.message,
                        );
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(Lang.t("advice_saved")),
                              backgroundColor: Colors.blue,
                           ));
                        }
                     } catch (e) {
                        debugPrint("Manual chat save error: $e");
                     }
                  },
                );
              },
            ),
          ),
          _InputArea(
            controller: _controller,
            isListening: _isListening,
            onSend: () => send(_controller.text),
            onMic: toggleListening,
          ),
        ],
      ),
    );
  }
}

class EdgeChat {
  final String user;
  final String message;
  final bool isUser;

  EdgeChat({required this.user, required this.message, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final VoidCallback onVoice;
  final VoidCallback? onSave;

  const _ChatBubble({required this.message, required this.isUser, required this.onVoice, this.onSave});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty)
              isUser 
                ? Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )
                : MarkdownBody(
                    data: message,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
            if (!isUser && message.isNotEmpty && message != "Thinking...")
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onSave != null)
                    GestureDetector(
                      onTap: onSave,
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.bookmark_add_outlined, size: 18, color: Colors.blue),
                      ),
                    ),
                  GestureDetector(
                    onTap: onVoice,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green[50] ,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.volume_up, size: 18, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onMic;

  const _InputArea({
    required this.controller,
    required this.isListening,
    required this.onSend,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : Colors.grey),
            onPressed: onMic,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: Lang.t("type_msg"),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.green[700],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}