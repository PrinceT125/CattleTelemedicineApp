
import 'package:cattle_t/CattleOwnerScreen/edit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'StartConsultation.dart';



class Cattlerecord extends StatefulWidget {
  @override
  _CattleRecord createState() => _CattleRecord();
}

class _CattleRecord extends State<Cattlerecord> {
  late Stream<List<Cattle>> _cattleStream;

  @override
  void initState() {
    super.initState();
    _cattleStream = _fetchCattle();
  }

  Stream<List<Cattle>> _fetchCattle() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    final ownerId = user.uid;

    return FirebaseFirestore.instance
        .collection('owners')
        .doc(ownerId)
        .collection('cattle')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Cattle.fromDoc(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cattle"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose your pet you want to consult for",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildAddCattleCard(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Cattle>>(
                stream: _cattleStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final cattleList = snapshot.data ?? [];
                  if (cattleList.isEmpty) {
                    return const Center(child: Text("No cattle found."));
                  }

                  return ListView.builder(
                    itemCount: cattleList.length,
                    itemBuilder: (context, index) {
                      final cattle = cattleList[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(Icons.edit, color: Colors.green),
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditCattlePage(cattle: cattle),
                                ),
                              );
                              if (updated != null) {
                                setState(() {
                                  _cattleStream = _fetchCattle();
                                });
                              }
                            },
                          ),
                          title: Text(cattle.name),
                          subtitle:
                          Text('${cattle.breed}, Age: ${cattle.age}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red.shade700),
                            onPressed: () => _deleteCattle(context, cattle),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCattle(BuildContext context, Cattle cattle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Cattle'),
        content: Text('Are you sure you want to delete ${cattle.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(user.uid)
              .collection('cattle')
              .doc(cattle.docId)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${cattle.name} has been deleted')),
          );

          setState(() {
            _cattleStream = _fetchCattle();
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting cattle: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildAddCattleCard() {
    return GestureDetector(
      onTap: () async {
        final newCattle = await Navigator.push<Cattle>(
          context,
          MaterialPageRoute(builder: (context) => AddCattlePage()),
        );
        if (newCattle != null) {
          setState(() {
            _cattleStream = _fetchCattle();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.add_circle_outline, size: 30, color: Colors.teal),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add new pet",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Click to create profile",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
