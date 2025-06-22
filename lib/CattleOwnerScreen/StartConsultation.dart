// consultation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cattle_t/CattleOwnerScreen/chatPage.dart';
import 'edit.dart';

class Cattle {
  final String docId;
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String description;

  Cattle({
    required this.docId,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.description,
  });

  factory Cattle.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cattle(
      docId: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? '',
      gender: data['gender'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'gender': gender,
      'description': description,
    };
  }
}

class ConsultationScreen extends StatefulWidget {
  @override
  _ConsultationScreenState createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  late Stream<List<Cattle>> _cattleStream;
  Cattle? selectedCattle;
  String selectedCategory = 'Dentistry';
  final List<String> categories = [
    'Dentistry',
    'General Checkup',
    'Vaccination',
    'Injury',
    'Skin Problems'
  ];
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cattleStream = _fetchCattle();
  }

  Stream<List<Cattle>> _fetchCattle() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    final ownerId = user.uid;

    return FirebaseFirestore.instance
        .collection('owners')
        .doc(ownerId)
        .collection('cattle')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Cattle.fromDoc(doc)).toList());
  }

  void _startConsultation() async {
    if (selectedCattle == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("No Cattle Selected"),
          content: Text("Please select a cattle or add a new one to proceed."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Select Existing"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddCattlePage())).then((newCattle) {
                  if (newCattle != null) {
                    setState(() {
                      _cattleStream = _fetchCattle();
                    });
                  }
                });
              },
              child: Text("Add New Cattle"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final vetsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'veterinarian')
          .where('approved', isEqualTo: true)
          .get();

      if (vetsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No approved veterinarians available.")),
        );
        return;
      }

      final vetDoc = (vetsSnapshot.docs..shuffle()).first;
      final vetData = vetDoc.data();

      final petName = selectedCattle!.name;
      final concern = selectedCategory;
      final description = descriptionController.text.trim();

      final cattleDetailsMessage = """
Cattle Name: $petName
Breed: ${selectedCattle!.breed}
Age: ${selectedCattle!.age}
Gender: ${selectedCattle!.gender}
Description: ${selectedCattle!.description}
Concern: $concern
Description of Issue: $description
""";

      final chatMessage = {
        'sender': 'owner',
        'message': cattleDetailsMessage,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final consultationRef =
      FirebaseFirestore.instance.collection('consultations').doc();
      await consultationRef.set({
        'vetUid': vetDoc.id,
        'ownerUid': FirebaseAuth.instance.currentUser!.uid,
        'cattleId': selectedCattle!.docId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await consultationRef.collection('messages').add(chatMessage);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            vetUid: vetDoc.id,
            vetName: vetData['name'] ?? 'Vet',
            petName: petName,
            concern: concern,
            description: description,
            consultationId: consultationRef.id,
            selectedCattleData: selectedCattle!.toMap(),
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Consultation started with Dr. ${vetData['name']}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cattle"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Choose your pet you want to consult for",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildAddCattleCard(),
              SizedBox(height: 12),

              // Use SizedBox with fixed height OR wrap StreamBuilder in its own Expanded inside a Flexible layout
              SizedBox(
                height: 300, // Or any height you feel appropriate
                child: StreamBuilder<List<Cattle>>(
                  stream: _cattleStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    final cattleList = snapshot.data ?? [];
                    if (cattleList.isEmpty) {
                      return Center(child: Text("No cattle added yet."));
                    }
                    return ListView.builder(
                      itemCount: cattleList.length,
                      itemBuilder: (context, index) {
                        final cattle = cattleList[index];
                        bool isSelected = selectedCattle == cattle;
                        return Card(
                          color: isSelected ? Colors.teal.shade50 : Colors.white,
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(Icons.edit, color: Colors.green),
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditCattlePage(cattle: cattle),
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
                            subtitle: Text("${cattle.breed}, Age: ${cattle.age}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text("Delete ${cattle.name}?"),
                                    content: Text("Are you sure?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final user = FirebaseAuth.instance.currentUser;
                                  await FirebaseFirestore.instance
                                      .collection('owners')
                                      .doc(user!.uid)
                                      .collection('cattle')
                                      .doc(cattle.docId)
                                      .delete();
                                  setState(() {
                                    _cattleStream = _fetchCattle();
                                    if (selectedCattle == cattle) {
                                      selectedCattle = null;
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("${cattle.name} deleted.")),
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              setState(() {
                                selectedCattle =
                                selectedCattle == cattle ? null : cattle;
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              _buildCategoryDropdown(),
              SizedBox(height: 20),
              _buildDescriptionInput(),
              SizedBox(height: 20),
              _buildStartConsultationButton(),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: "Select Concern",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (value) => setState(() => selectedCategory = value!),
    );
  }

  Widget _buildDescriptionInput() {
    return TextField(
      controller: descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: "Describe your concern",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStartConsultationButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.chat),
      label: Center(child: Text("Start Consultation")),
      onPressed: _startConsultation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal:100),
      ),
    );
  }

  Widget _buildAddCattleCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddCattlePage()),
        ).then((value) {
          if (value != null) {
            setState(() {
              _cattleStream = _fetchCattle();
            });
          }
        });
      },
      child: Card(
        color: Colors.green[100],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text(
                "Add New Cattle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
