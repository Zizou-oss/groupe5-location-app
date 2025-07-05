import 'package:flutter/material.dart';
import '../models/message.dart';
import '../data/mock_messages.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String peerUserId;
  final String peerUserName;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.peerUserId,
    required this.peerUserName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  List<Message> get _chatMessages {
    return mockMessages.where((m) =>
      (m.senderId == widget.currentUserId && m.receiverId == widget.peerUserId) ||
      (m.senderId == widget.peerUserId && m.receiverId == widget.currentUserId)
    ).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final msg = Message(
      senderId: widget.currentUserId,
      receiverId: widget.peerUserId,
      text: _controller.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      mockMessages.add(msg);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isMe = msg.senderId == widget.currentUserId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.teal : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
