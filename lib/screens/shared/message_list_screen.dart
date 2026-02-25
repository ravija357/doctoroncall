import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_event.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/screens/shared/chat_screen.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadContactsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)));
          } else if (state is ChatError) {
            return Center(child: Text(state.message));
          } else if (state is ContactsLoaded) {
            final contacts = state.contacts;
            
            if (contacts.isEmpty) {
              return const Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: contact.image != null 
                        ? ImageUtils.getImageProvider(contact.image) 
                        : null,
                    child: contact.image == null 
                        ? const Icon(Icons.person) 
                        : null,
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    contact.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: contact.unread > 0 
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF6AA9D8),
                          child: Text(
                            contact.unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: contact.id,
                          otherUserName: contact.name,
                        ),
                      ),
                    ).then((_) {
                      context.read<ChatBloc>().add(LoadContactsRequested());
                    });
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
