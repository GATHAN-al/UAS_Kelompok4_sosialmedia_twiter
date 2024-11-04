import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uas_twitter_mediasosial/components/my_drawer.dart';
import 'package:uas_twitter_mediasosial/components/my_input_alert_box.dart';
import 'package:uas_twitter_mediasosial/components/my_post_tile.dart';
import 'package:uas_twitter_mediasosial/database/database_provider.dart';

import '../models/post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final listeningProvider = Provider.of<DatabaseProvider>(context);

  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

final _messageController = TextEditingController();

@override
  void initState() {
    super.initState();

    loadAllPosts();
  }

  Future<void> loadAllPosts() async{
    await databaseProvider.loadAllPosts();
  }
//show post message
void _openPostMessageBox() {
  showDialog(
    context: context, 
    builder: (context) => MyInputAlertBox(
      textController: _messageController,
      hinText: "What's on your mind?",
       onPressed: ()async {
        await postMessage(_messageController.text);
       },
       onPressedText: "Post",
    ),
  );
}

//user post
Future<void> postMessage(String message) async{
 await databaseProvider.postMessage(message);
}
  // UI
  @override
  Widget build(BuildContext context) {

    //
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer:  MyDrawer(),



      // App bar
      appBar: AppBar(
        title: const Text("H O M E"),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openPostMessageBox,
        child:const Icon(Icons.add),
        ),

        body:  _buildPostlist(listeningProvider.allPots),
    );
  }
  Widget _buildPostlist(List<Post> posts) {
return posts.isEmpty ? 
 const Center(
  child: Text("Nothing here.."),
)
 : ListView.builder(
  itemCount: posts.length,
  itemBuilder: (context, index) {
    final post = posts[index];

    return MyPostTile(post: post);
 }
 );
  }
}
