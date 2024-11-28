import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uas_twitter_mediasosial/database/database_service.dart';
import 'package:uas_twitter_mediasosial/models/user.dart';


class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserProfile user;

  const ChatScreen({super.key, required this.chatId, required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _dbService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, String> _userNamesCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.user.name}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>( 
              stream: _dbService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  reverse: true, // Display latest messages at the bottom
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByCurrentUser = message['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? "${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                        : "Unknown time";

                        // Replace the part where you display messages with imageUrl check
                        return Column(
                          crossAxisAlignment: isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Display sender's name above the message bubble 
                            FutureBuilder<String?>( 
                              future: _getUserName(message['senderId']),
                              builder: (context, nameSnapshot) {
                                final senderName = nameSnapshot.data ?? "Unknown";
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
                            ),
                            Align(
                              alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: isSentByCurrentUser ? const Color.fromARGB(255, 39, 249, 11) : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: message.containsKey('imageUrl') && message['imageUrl'] != null && message['imageUrl'].isNotEmpty
                                    ? Container(
                                        width: 200, // Specify the width of the image container
                                        height: 200, // Specify the height of the image container
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: NetworkImage(message['imageUrl']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Message text
                                              Flexible(
                                                child: Text(
                                                  message['text'] ?? '',
                                                  style: TextStyle(
                                                    color: isSentByCurrentUser ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              // Timestamp to the right of message text
                                              Text(
                                                formattedTime,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isSentByCurrentUser ? Colors.white70 : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showImageUrlDialog(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getUserName(String uid) async {
    if (_userNamesCache.containsKey(uid)) {
      return _userNamesCache[uid];
    } else {
      final name = await _dbService.getUserName(uid);
      setState(() {
        _userNamesCache[uid] = name ?? 'Unknown';
      });
      return name;
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      await _dbService.sendMessage(
        chatId: widget.chatId,
        senderId: currentUserId,
        message: text,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _sendImageMessage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      await _dbService.sendMessage(
        chatId: widget.chatId,
        senderId: currentUserId,
        message: '', // Empty text message, because we're sending an image
        imageUrl: imageUrl, // Send image URL
      );
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Since we're reversing the list, 0.0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showImageUrlDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Image'),
          content: TextField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              hintText: 'Enter image URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _sendImageMessage(_imageUrlController.text.trim());
                _imageUrlController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
