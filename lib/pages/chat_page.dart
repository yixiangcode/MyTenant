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

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead(widget.receiverId);
  }

  Future<void> sendMessage(String receiverId) async {
    if (_messageController.text.trim().isEmpty) return;

    if (receiverId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Please accept landlord invitation first.')),
        );
      }
      return;
    }

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    Map<String, dynamic> messageData = {
      'senderId': currentUserId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    final receiverUnreadCountField = '${receiverId}_unreadCount';

    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      receiverUnreadCountField: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> _markMessagesAsRead(String receiverId) async {
    if (receiverId.isEmpty) return;

    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isEqualTo: receiverId)
          .where('read', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'read': true, 'readAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }

      await _firestore.collection('chats').doc(chatRoomId).update({
        '${currentUserId}_unreadCount': 0,
      });

    } catch (e) {
      if (mounted) {
        print('Error marking messages as read: $e');
      }
    }
  }


  Widget _buildMessageList(String receiverId) {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

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
    final bool isRead = data.containsKey('read') && data['read'] == true;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
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
          if (isCurrentUser && isRead)
            const Padding(
              padding: EdgeInsets.only(top: 2.0, right: 4.0),
              child: Icon(Icons.done_all, size: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(String receiverId) {
    final bool canSend = receiverId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSend,
              decoration: InputDecoration(
                hintText: canSend ? 'Type a message...' : 'Please wait / Invitation pending...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: canSend ? Colors.white : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: canSend ? Colors.indigoAccent : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: canSend ? () => sendMessage(receiverId) : null,
            ),
          ),
          const SizedBox(height: 75.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

        final String fetchedLandlordId = userData?['landlordId'] as String? ?? '';

        final String currentReceiverId = fetchedLandlordId.isNotEmpty ? fetchedLandlordId : widget.receiverId;

        final bool canChat = currentReceiverId.isNotEmpty;


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
                child: canChat
                    ? _buildMessageList(currentReceiverId)
                    : const Center(child: Text('Please accept the invitation to start chatting.')),
              ),
              _buildMessageInput(canChat ? currentReceiverId : ''),
            ],
          ),
        );
      },
    );
  }
}