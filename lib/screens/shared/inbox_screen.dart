import 'package:flutter/material.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: 0, // TODO: Fetch conversation list
        itemBuilder: (context, index) {
          return const ListTile(
            leading: CircleAvatar(),
            title: Text('User Name'),
            subtitle: Text('Last message snippet...'),
            trailing: Text('12:00 PM'),
          );
        },
      ),
    );
  }
}
