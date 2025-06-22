import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String vetUid, vetName, petName, concern, description, consultationId;
  final Map<String, dynamic> selectedCattleData;

  ChatPage({
    required this.vetUid,
    required this.vetName,
    required this.petName,
    required this.concern,
    required this.description,
    required this.consultationId,
    required this.selectedCattleData,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late String currentUserId, chatId;

  // String callId = Uuid().v4();
  DocumentReference? _callDoc;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    chatId = _generateChatId(currentUserId, widget.vetUid);
    _initializeChat();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _generateChatId(String a, String b) {
    final l = [a, b]..sort();
    return l.join('_');
  }

  Future<void> _initializeChat() async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      await chatDoc.set({
        'participants': [currentUserId, widget.vetUid],
        'createdAt': FieldValue.serverTimestamp(),
        'petName': widget.petName,
        'concern': widget.concern,
        'description': widget.description,
        'consultationId': widget.consultationId,
      });

      await _sendSystemMessage("""
Hello! I'm Dr. ${widget.vetName}'s assistant.
We're consulting for ${widget.petName}.
Concern: ${widget.concern}
Description: ${widget.description}

Here are the details of the cattle:
Name: ${widget.selectedCattleData['name']}
Breed: ${widget.selectedCattleData['breed']}
Age: ${widget.selectedCattleData['age']}
Gender: ${widget.selectedCattleData['gender']}
Description: ${widget.selectedCattleData['description']}
""");
    } else {
      await _sendSystemMessage("""
New cattle added:
Name: ${widget.selectedCattleData['name']}
Breed: ${widget.selectedCattleData['breed']}
Age: ${widget.selectedCattleData['age']}
Gender: ${widget.selectedCattleData['gender']}
Description: ${widget.selectedCattleData['description']}
""");
    }
  }

  Future<void> _sendSystemMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': 'assistant',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _sendUserMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C5D50),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.vetName, style: TextStyle(fontSize: 16)),
            Text(widget.concern, style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [],
      ),
      backgroundColor: Color(0xFFF2F2F2),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream(),
              builder: (_, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;

                String? lastMessageDate;

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final isMe = m['senderId'] == currentUserId;
                    final ts = m['timestamp'] as Timestamp?;
                    final dt = ts?.toDate() ?? DateTime.now();
                    final dateStr = _messageDateLabel(dt);
                    final showDateDivider = dateStr != lastMessageDate;
                    lastMessageDate = dateStr;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateDivider)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: <Widget>[
                                Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(dateStr, style: TextStyle(color: Colors.grey)),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Color(0xFFDCF8C6) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['text']),
                                SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(ts),
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _sendUserMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return "$h:$min $ap";
  }

  String _messageDateLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}-${_month(dt.month)}-${dt.year}';
    }
  }

  String _month(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }
}
