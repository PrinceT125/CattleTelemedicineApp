import 'package:cattle_t/VeterinarianScreen/vetChatpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeContentPage extends StatelessWidget {
  final String vetUid;
  const HomeContentPage({Key? key, required this.vetUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMessagesFromPetOwners(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(vetUid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final vetName = data?['name'] ?? 'Veterinarian';

        return _headerContent('Hello, Dr. $vetName');
      },
    );
  }

  Widget _headerContent(String greetingText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade700.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greetingText,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ready to care for your patients today?',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesFromPetOwners(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Messages from Pet Owners',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: vetUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error loading chats.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chatDocs = snapshot.data!.docs;

            if (chatDocs.isEmpty) {
              return const Text('No chats yet.');
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLatestMessages(chatDocs, vetUid),
              builder: (context, latestSnap) {
                if (!latestSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sortedChats = latestSnap.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedChats.length,
                  itemBuilder: (context, index) {
                    final chat = sortedChats[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[700],
                          child:
                          const Icon(Icons.person, color: Colors.white),
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
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
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
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLatestMessages(
      List<QueryDocumentSnapshot> chats, String vetUid) async {
    List<Map<String, dynamic>> chatList = [];

    for (var chatDoc in chats) {
      final chatId = chatDoc.id;
      final participants = List<String>.from(chatDoc['participants']);
      final petOwnerUid = participants.firstWhere((id) => id != vetUid);

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(petOwnerUid)
          .get();
      final petOwnerName =
      (userSnap.data()?['name'] ?? 'Unknown') as String;

      // Fetch last message
      final msgSnap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (msgSnap.docs.isEmpty) {
        continue; // Skip if no messages
      }

      final msgDoc = msgSnap.docs.first;
      final lastMessage = msgDoc['text'];
      final lastTimestamp = msgDoc['timestamp'];

      chatList.add({
        'chatId': chatId,
        'petOwnerUid': petOwnerUid,
        'petOwnerName': petOwnerName,
        'lastMessage': lastMessage,
        'lastTimestamp': lastTimestamp,
      });
    }

    // Sort by timestamp
    chatList.sort((a, b) =>
        (b['lastTimestamp'] as Timestamp).compareTo(a['lastTimestamp'] as Timestamp));

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
