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
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
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

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.indigoAccent : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          data['message'] ?? '',
          style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black, fontSize: 16),
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
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('assets')
            .where('landlordId', isEqualTo: currentUserId)
            .where('tenantId', isEqualTo: widget.receiverId)
            .snapshots(),
        builder: (context, snapshot) {
          bool isConnected = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          // tenant view
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('assets')
                .where('tenantId', isEqualTo: currentUserId)
                .where('landlordId', isEqualTo: widget.receiverId)
                .snapshots(),
            builder: (context, tenantSnapshot) {
              bool isConnectedAsTenant = tenantSnapshot.hasData && tenantSnapshot.data!.docs.isNotEmpty;
              bool canChat = isConnected || isConnectedAsTenant;

              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  Expanded(child: _buildMessageList()),
                  canChat
                      ? _buildMessageInput()
                      : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    //color: Colors.red[100],
                    child: const Text(
                      'Access Denied: You are no longer connected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              );
            },
          );
        },
      ),
    );
  }
}