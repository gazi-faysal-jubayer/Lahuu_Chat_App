import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lahuu_chat_app/models/chat.dart';
import 'package:lahuu_chat_app/models/message.dart';
import 'package:lahuu_chat_app/models/user_profile.dart';
import 'package:lahuu_chat_app/services/auth_service.dart';
import 'package:lahuu_chat_app/services/database_service.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

  const ChatPage({
    super.key,
    required this.chatUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;

  ChatUser? currentUser, otherUser;

  late AuthService _authService;
  late DatabaseService _databaseService;

  // Initialize ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();

    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: _authService.user!.displayName,
    );
    otherUser = ChatUser(
      id: widget.chatUser.uid!,
      firstName: widget.chatUser.name,
      profileImage: widget.chatUser.pfpURL,
    );

    print("Current User: ${currentUser?.firstName}, Other User: ${otherUser?.firstName}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatUser.name!),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error loading chat: ${snapshot.error}");
          return const Center(
            child: Text("Error loading chat."),
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          print("No chat data available");
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Convert snapshot data to Chat object
        var chatData = snapshot.data!.data()!;
        Chat chat = Chat.fromJson(chatData);

        // Reverse messages to show latest at the bottom
        List<ChatMessage> messages = _generateChatMessagesList(chat.messages!).reversed.toList();

        // Scroll to bottom after data loads
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return DashChat(
          messageOptions: const MessageOptions(
            showOtherUsersAvatar: true,
            showTime: true,
          ),
          inputOptions: const InputOptions(
            alwaysShowSend: true,
          ),
          currentUser: currentUser!,
          onSend: _sendMessage,
          messages: messages,
        );
      },
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    Message message = Message(
      senderID: currentUser!.id,
      content: chatMessage.text,
      messageType: MessageType.Text,
      sentAt: Timestamp.fromDate(chatMessage.createdAt),
    );
    await _databaseService.sendChatMessage(
      currentUser!.id,
      otherUser!.id,
      message,
    );

    // Scroll to the bottom after sending the message
    _scrollToBottom();
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    return messages.map((m) {
      return ChatMessage(
        user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
        text: m.content!,
        createdAt: m.sentAt!.toDate(),
      );
    }).toList();
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
}
