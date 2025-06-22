import 'package:cattle_t/CattleOwnerScreen/vetchatscreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListPage extends StatelessWidget {
  final String petOwnerUid;

  const ChatListPage({Key? key, required this.petOwnerUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats with Veterinarians'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: petOwnerUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading chats'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatDocs = snapshot.data!.docs;
          if (chatDocs.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchSortedChats(chatDocs),
            builder: (context, sortedSnapshot) {
              if (!sortedSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sortedChats = sortedSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sortedChats.length,
                itemBuilder: (context, index) {
                  final chat = sortedChats[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[700],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        chat['vetName'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      subtitle: Text(
                        chat['lastMessage'] ?? 'No messages yet.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(chat['timestamp']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VetChatScreen(
                              chatId: chat['chatId'],
                              petOwnerUid: petOwnerUid,
                              vetUid: chat['vetUid'],
                              vetName: chat['vetName'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSortedChats(
      List<QueryDocumentSnapshot> chatDocs) async {
    List<Map<String, dynamic>> chatList = [];

    for (var chatDoc in chatDocs) {
      final chatId = chatDoc.id;
      final participants = List<String>.from(chatDoc['participants']);
      final vetUid = participants.firstWhere((id) => id != petOwnerUid);

      // Get vet name
      final vetSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(vetUid)
          .get();
      final vetName = (vetSnap.data()?['name'] ?? 'Unknown') as String;

      // Get latest message
      final messageSnap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messageSnap.docs.isEmpty) continue;

      final messageData = messageSnap.docs.first.data();
      final lastMessage = messageData['text'] ?? '';
      final timestamp = messageData['timestamp'] as Timestamp;

      chatList.add({
        'chatId': chatId,
        'vetUid': vetUid,
        'vetName': vetName,
        'lastMessage': lastMessage,
        'timestamp': timestamp,
      });
    }

    // Sort by latest message timestamp
    chatList.sort((a, b) =>
        (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    return chatList;
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();

    final time = "${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";

    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final date = isToday ? 'Today' : "${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}";

    return "$time\n$date";
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

}
