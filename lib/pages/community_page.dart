import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'community_detail_page.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('C O M M U N I T Y'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateCommunityDialog,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Text(
            'Discover new Communities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          ..._buildCommunityList(),
        ],
      ),
    );
  }

  List<Widget> _buildCommunityList() {
    return [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('communities').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final communities = snapshot.data!.docs;

          return Column(
            children: communities.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildCommunityTile(
                context,
                doc.id, // Community ID
                data['name'] ?? '',
                data['members'] != null ? '${data['members']} Members' : '0 Members',
                data['category'] ?? '',
                data['createdBy'] ?? '',
              );
            }).toList(),
          );
        },
      ),
    ];
  }

  Widget _buildCommunityTile(BuildContext context, String id, String name, String members, String category, String createdBy) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[300],
      ),
      title: Text(
        name,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$members • $category'),
      trailing: currentUserId == createdBy
          ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteCommunityDialog(id),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CommunityDetailPage(communityName: name)),
        );
      },
    );
  }

  void _showCreateCommunityDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Community'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Community Name'),
              ),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                await FirebaseFirestore.instance.collection('communities').doc(nameController.text).set({
                  'name': nameController.text,
                  'category': categoryController.text,
                  'members': 0,
                  'createdBy': currentUserId, // Simpan UID pembuat komunitas
                });

                Navigator.pop(context);
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCommunityDialog(String communityId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Community"),
          content: Text("Are you sure you want to delete this community? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCommunity(communityId);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCommunity(String communityId) async {
    final communityRef = FirebaseFirestore.instance.collection('communities').doc(communityId);

    try {
      // Hapus semua anggota
      final membersSnapshot = await communityRef.collection('members').get();
      for (var member in membersSnapshot.docs) {
        await member.reference.delete();
      }

      // Hapus semua postingan
      final postsSnapshot = await communityRef.collection('posts').get();
      for (var post in postsSnapshot.docs) {
        await post.reference.delete();
      }

      // Hapus dokumen komunitas
      await communityRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Community deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete community: $e')),
      );
    }
  }
}
