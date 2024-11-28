import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uas_twitter_mediasosial/models/user.dart';
import 'profile_page.dart'; // Import ProfilePage

class CommunityDetailPage extends StatefulWidget {
  final String communityName;

  CommunityDetailPage({required this.communityName});

  @override
  _CommunityDetailPageState createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool _isJoined = false;
  TextEditingController _postController = TextEditingController();
  TextEditingController _urlController = TextEditingController();
  UserProfile? currentUserProfile;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _checkIfJoined();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });

      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          currentUserProfile = UserProfile.fromDocument(userDoc);
        });
      }
    }
  }

  Future<void> _checkIfJoined() async {
    if (currentUserId == null) return;
    final communityRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityName);

    final memberDoc = await communityRef.collection('members').doc(currentUserId).get();
    setState(() {
      _isJoined = memberDoc.exists;
    });
  }

  Future<void> _joinCommunity() async {
    if (currentUserId == null) return;
    final communityRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityName);

    await communityRef.collection('members').doc(currentUserId).set({
      'joined': true,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await communityRef.update({
      'members': FieldValue.increment(1),
    });

    setState(() {
      _isJoined = true;
    });
  }

  Future<void> _leaveCommunity() async {
    if (currentUserId == null) return;
    final communityRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityName);

    await communityRef.collection('members').doc(currentUserId).delete();

    await communityRef.update({
      'members': FieldValue.increment(-1),
    });

    setState(() {
      _isJoined = false;
    });
  }

  Future<void> _addPost(String text, String imageUrl) async {
    if (currentUserId == null || currentUserProfile == null) return;
    final communityRef = FirebaseFirestore.instance.collection('communities').doc(widget.communityName);

    await communityRef.collection('posts').add({
      'text': text,
      'imageUrl': imageUrl, // Simpan URL gambar
      'username': currentUserProfile!.name,
      'userId': currentUserId,
      'time': FieldValue.serverTimestamp(),
      'likes': 0,
      'likeBy': [],
    });
  }

  Future<void> _toggleLike(DocumentSnapshot post) async {
    if (currentUserId == null) return;
    final postRef = post.reference;
    final List<dynamic> likeBy = post['likeBy'] ?? [];

    if (likeBy.contains(currentUserId)) {
      likeBy.remove(currentUserId);
    } else {
      likeBy.add(currentUserId);
    }

    await postRef.update({'likeBy': likeBy, 'likes': likeBy.length});
  }

  Future<void> _deletePost(DocumentSnapshot post) async {
    try {
      await post.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        actions: [
          if (_isJoined)
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _showLeaveConfirmationDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCommunityHeader(),
          if (_isJoined) _buildPostInput(), // Only show post input if user has joined
          Expanded(child: _buildPostsList()),
        ],
      ),
    );
  }

  Widget _buildCommunityHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.communityName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (!_isJoined)
            ElevatedButton(
              onPressed: _joinCommunity,
              child: Text("Join Community"),
            ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _postController,
            decoration: InputDecoration(hintText: "Write a post..."),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(hintText: "Enter image URL (optional)..."),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_postController.text.isNotEmpty) {
                      _addPost(_postController.text, _urlController.text);
                      _postController.clear();
                      _urlController.clear();
                    }
                  },
                  child: Text("Post"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityName)
          .collection('posts')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final bool isLiked = (post['likeBy'] as List).contains(currentUserId);
            final bool isOwner = post['userId'] == currentUserId;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(uid: post['userId']),
                          ),
                        );
                      },
                      child: Text(
                        post['username'] ?? "Anonymous",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (post['imageUrl'] != null && post['imageUrl'] != "")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.network(
                          post['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              "Image failed to load.",
                              style: TextStyle(color: Colors.red),
                            );
                          },
                        ),
                      ),
                    Text(post['text'] ?? ""),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => _toggleLike(post),
                            ),
                            Text('${post['likes'] ?? 0}'),
                          ],
                        ),
                        if (isOwner)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(post),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(DocumentSnapshot post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Post"),
          content: Text("Are you sure you want to delete this post?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePost(post);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Leave Community"),
          content: Text("Are you sure you want to leave this community?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _leaveCommunity();
                Navigator.pop(context);
              },
              child: Text("Leave"),
            ),
          ],
        );
      },
    );
  }
}
