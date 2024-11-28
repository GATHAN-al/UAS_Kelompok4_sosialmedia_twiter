import 'package:flutter/material.dart';
import 'package:uas_twitter_mediasosial/auth/auth_service.dart';
import 'package:uas_twitter_mediasosial/pages/chatting_page.dart';
import 'package:uas_twitter_mediasosial/pages/profile_page.dart';
import 'package:uas_twitter_mediasosial/pages/search_page.dart';

import '../pages/setting_page.dart';
import 'my_drawer_tile.dart';
import '../pages/community_page.dart';
import '../pages/subscription_page.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  final _auth = AuthService();

  void logout() {
    _auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              // logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              // divider line
              Divider(
                color: Theme.of(context).colorScheme.secondary,
              ),

              // home tile
              MyDrawerTile(
                title: "H O M E",
                icon: Icons.home,
                onTap: () => Navigator.of(context).pop(),
              ),

              // profile
              MyDrawerTile(
                title: "P R O F I L E",
                icon: Icons.person,
                onTap: () {
                  // pop menu drawer
                  Navigator.of(context).pop();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(uid: _auth.getCurrentUid()),
                    ),
                  );
                },
              ),

              // search tile
              MyDrawerTile(
                title: "S E A R C H",
                icon: Icons.search,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPage(),
                    )
                  );
                },
              ),

              // Chat Tile
              MyDrawerTile(
                title: "C H A T", 
                icon: Icons.chat, 
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(), // Ubah ke ChatPage
                    ),
                  );
                },
              ),
              
              MyDrawerTile(
                title: "C O M M U N I T Y",
                icon: Icons.people,
                onTap: () {
                  // pop menu drawer
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityPage(),
                    ),
                  );
                },
              ),


              MyDrawerTile(
                title: "S U B S C R I P T I O N",
                icon: Icons.star,
                onTap: () {
                  // pop menu drawer
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(),
                    ),
                  );
                },
              ),

              // settings tile
              MyDrawerTile(
                title: "S E T T I N G S",
                icon: Icons.settings,
                onTap: () {
                  // pop menu drawer
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingPage(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // logout tile
              MyDrawerTile(
                title: "L O G O U T",
                icon: Icons.login,
                onTap: logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
