import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (widget.receiverId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Please accept landlord invitation first.')),
        );
      }
      return;
    }

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    final String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);

    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, widget.receiverId],
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _buildMessageList() {
    final String chatRoomId = getChatRoomId(currentUserId, widget.receiverId);

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          reverse: true,
          padding: const EdgeInsets.only(bottom: 10, top: 10),
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data['senderId'] == currentUserId;

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    var color = isCurrentUser ? Colors.indigoAccent : Colors.white;
    var textColor = isCurrentUser ? Colors.white : Colors.black;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          data['message'],
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              //onSubmitted: (value) => sendMessage(), // Press enter to send
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.indigoAccent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
          const SizedBox(height: 75.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.purple[50],

      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}