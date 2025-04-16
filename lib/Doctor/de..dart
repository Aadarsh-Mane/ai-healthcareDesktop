import 'package:flutter/material.dart';

class CustomSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implement search results
    return ListView(
      children: [
        ListTile(
          title: Text('Search Result 1'),
          onTap: () {
            // Handle result selection
          },
        ),
      ],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Implement search suggestions
    return ListView(
      children: [
        ListTile(
          title: Text('Suggested Result 1'),
          onTap: () {
            query = 'Suggested Result 1';
          },
        ),
      ],
    );
  }
}

// Advanced User Profile Widget
class UserProfileWidget extends StatelessWidget {
  final String userName;
  final String userRole;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const UserProfileWidget({
    Key? key,
    required this.userName,
    required this.userRole,
    required this.onProfileTap,
    required this.onLogoutTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Animated Avatar with Status
        Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                'https://example.com/user-avatar.jpg',
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2843),
              ),
            ),
            Text(
              userRole,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(width: 10),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade700,
          ),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            switch (value) {
              case 'profile':
                onProfileTap();
                break;
              case 'settings':
                // Navigate to settings
                break;
              case 'logout':
                onLogoutTap();
                break;
            }
          },
        ),
      ],
    );
  }
}
