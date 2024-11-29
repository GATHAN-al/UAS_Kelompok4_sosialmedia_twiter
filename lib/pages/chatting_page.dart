import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uas_twitter_mediasosial/models/user.dart';
import 'package:uas_twitter_mediasosial/database/database_service.dart';
import 'package:uas_twitter_mediasosial/pages/chatScreen.dart'; // Halaman chat baru


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _dbService = DatabaseService();
  TextEditingController _searchController = TextEditingController();
  List<UserProfile> _users = [];
  UserProfile? _lastChattedUser; // Tambahkan variabel untuk user terakhir
  bool _isSearching = false; // Indikator apakah sedang searching

  // Fungsi pencarian berdasarkan nama
  void searchUsers() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true; // Mulai mencari
      });
      List<UserProfile> users = await _dbService.searchUsersByName(query);
      setState(() {
        _users = users;
      });
    } else {
      setState(() {
        _isSearching = false; // Berhenti mencari
        _users = [];
      });
    }
  }

  void _navigateToChat(UserProfile user) async {
    // Mendapatkan chatId antara pengguna saat ini dan pengguna yang dipilih
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String chatId = await _dbService.getOrCreateChatId(currentUserId, user.uid);

    // Simpan user terakhir yang di-chat
    setState(() {
      _lastChattedUser = user;
    });

    // Navigasi ke halaman chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId, user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
        title: const Text("C H A T"),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => searchUsers(),
              decoration: InputDecoration(
                hintText: "Search by name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Recent",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSearching
                ? ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () => _navigateToChat(user),
                      );
                    },
                  )
                : _lastChattedUser != null
                    ? ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(_lastChattedUser!.name),
                        subtitle: Text(_lastChattedUser!.email),
                        onTap: () => _navigateToChat(_lastChattedUser!),
                      )
                    : const Center(child: Text("No recent chats")),
          ),
        ],
      ),
    );
  }
}
