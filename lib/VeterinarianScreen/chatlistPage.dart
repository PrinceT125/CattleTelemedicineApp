import 'package:cattle_t/VeterinarianScreen/vetChatpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListPage extends StatelessWidget {
  final String vetUid;
  const ChatListPage({Key? key, required this.vetUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats with Pet Owners'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: vetUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading chats'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchLatestMessages(chats, vetUid),
            builder: (context, latestSnap) {
              if (!latestSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sortedChats = latestSnap.data!;
              final today = <Map<String, dynamic>>[];
              final earlier = <Map<String, dynamic>>[];

              final now = DateTime.now();

              for (var chat in sortedChats) {
                final ts = chat['lastTimestamp'] as Timestamp;
                final dt = ts.toDate();
                if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                  today.add(chat);
                } else {
                  earlier.add(chat);
                }
              }

              final combinedChats = <Map<String, dynamic>>[];

              if (today.isNotEmpty) {
                combinedChats.add({'isTodayDivider': true});
                combinedChats.addAll(today);
              }
              if (earlier.isNotEmpty) {
                combinedChats.add({'isEarlierDivider': true});
                combinedChats.addAll(earlier);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: combinedChats.length,
                itemBuilder: (context, index) {
                  final chat = combinedChats[index];

                  if (chat['isTodayDivider'] == true) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }

                  if (chat['isEarlierDivider'] == true) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Earlier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[700],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        chat['petOwnerName'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      subtitle: Text(
                        chat['lastMessage'] ?? 'No messages yet.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(chat['lastTimestamp']),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chat['chatId'],
                              vetUid: vetUid,
                              petOwnerUid: chat['petOwnerUid'],
                              petOwnerName: chat['petOwnerName'],
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

  Future<List<Map<String, dynamic>>> _fetchLatestMessages(
      List<QueryDocumentSnapshot> chats,
      String vetUid,
      ) async {
    List<Map<String, dynamic>> chatList = [];

    for (var chatDoc in chats) {
      final chatId = chatDoc.id;
      final participants = List<String>.from(chatDoc['participants']);
      final petOwnerUid = participants.firstWhere((id) => id != vetUid);

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(petOwnerUid)
          .get();
      final petOwnerName = (userSnap.data()?['name'] ?? 'Unknown') as String;

      final msgSnap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String? lastMessage;
      Timestamp? lastTimestamp;

      if (msgSnap.docs.isNotEmpty) {
        final msgDoc = msgSnap.docs.first;
        lastMessage = msgDoc['text'];
        lastTimestamp = msgDoc['timestamp'];
      }

      chatList.add({
        'chatId': chatId,
        'petOwnerUid': petOwnerUid,
        'petOwnerName': petOwnerName,
        'lastMessage': lastMessage ?? '',
        'lastTimestamp': lastTimestamp ?? Timestamp.now(),
      });
    }

    chatList.sort((a, b) => (b['lastTimestamp'] as Timestamp)
        .compareTo(a['lastTimestamp'] as Timestamp));

    return chatList;
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();

    final time =
        "${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";

    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final date = isToday
        ? 'Today'
        : "${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}";

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
