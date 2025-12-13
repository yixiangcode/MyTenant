import 'package:flutter/material.dart';
import 'package:tenant/pages/maintenance_page.dart';
import 'package:tenant/pages/owing_page.dart';
import 'package:tenant/pages/scanner_page.dart';

class MessageAction {
  final String label;
  final WidgetBuilder pageBuilder;

  MessageAction({required this.label, required this.pageBuilder});
}

enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final MessageAction? action;

  ChatMessage({required this.text, required this.sender, this.action});
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  void _handleSubmitted(String text) {
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.insert(0, ChatMessage(text: text, sender: MessageSender.user));
      _isSending = true;
    });

    _textController.clear();

    Future.delayed(const Duration(seconds: 2), () {
      final response = _getMockAIResponse(text);

      setState(() {
        _messages.insert(0, response);
        _isSending = false;
      });
    });
  }

  ChatMessage _getMockAIResponse(String userText) {
    userText = userText.toLowerCase();

    if (userText.contains('fix') || userText.contains('broken') || userText.contains('problem')) {
      final action = MessageAction(
        label: "Request Maintenance",
        pageBuilder: (context) => const MaintenancePage(),
      );
      return ChatMessage(
        text: "Which facility do you need repaired? Please click the button below to request a maintenance.",
        sender: MessageSender.ai,
        action: action,
      );

    } else if (userText.contains('pay') || userText.contains('rent') || userText.contains('fee')) {
      final action = MessageAction(
        label: "Check Owing Records",
        pageBuilder: (context) => const OwingPage(),
      );
      return ChatMessage(
        text: "Your rent payment date is the 5th of each month. Click the button to view records or make a payment.",
        sender: MessageSender.ai,
        action: action,
      );

    } else if (userText.contains('doc') || userText.contains('scan') || userText.contains('bill')) {
      final action = MessageAction(
        label: "Document Scanner",
        pageBuilder: (context) => ScannerPage(),
      );
      return ChatMessage(
        text: "Please click the button below to upload your documents.",
        sender: MessageSender.ai,
        action: action,
      );

    } else {
      return ChatMessage(
        text: "Hello, I'm your AI assistant, and I'm happy to assist you. Do you have any questions about the rental agreement, facility repairs, or community rules?",
        sender: MessageSender.ai,
      );
    }
  }

  void _executeAction(MessageAction action) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: action.pageBuilder),
    );
  }

  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Ask AI Assistance...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              enabled: !_isSending,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            decoration: BoxDecoration(
              color: _isSending ? Colors.grey : Colors.indigoAccent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isSending ? Icons.hourglass_top : Icons.send,
                color: Colors.white,
              ),
              onPressed: _isSending
                  ? null
                  : () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Colors.indigoAccent,
              child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
            ),

          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(left: isUser ? 50.0 : 8.0, right: isUser ? 8.0 : 50.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.indigoAccent : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 15 : 0),
                      topRight: Radius.circular(isUser ? 0 : 15),
                      bottomLeft: const Radius.circular(15),
                      bottomRight: const Radius.circular(15),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2.0,
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                if (!isUser && message.action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _executeAction(message.action!),
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(message.action!.label),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text("T", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Tenant Assistance"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      backgroundColor: Colors.purple[50],

      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _buildChatMessage(_messages[index]),
            ),
          ),

          _buildTextComposer(),

          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}