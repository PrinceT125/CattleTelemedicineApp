import 'package:cattle_t/CattleOwnerScreen/drawer.dart';
import 'package:cattle_t/signin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../CattleOwnerScreen/StartConsultation.dart';
import '../CattleOwnerScreen/Farmer_Profile.dart';
import 'package:flutter/material.dart';

class IntroPage extends StatefulWidget {
  final String uid;
  const IntroPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final List<Map<String, dynamic>> categories = [
    {'title': 'Cattles', 'image': "assets/images/h.jpg"},
  ];

  String? userName;

  @override
  void initState() {
    super.initState();
    _getCurrentUserName();
  }

  Future<void> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userName = doc.exists && doc.data()!.containsKey('name')
            ? doc['name']
            : user.displayName ?? 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = userName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text("Cattle Telemedicine"),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Hello, $greeting 👋",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20,),
          // Banner Section
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/a.jpg',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),

          // Greeting

          const SizedBox(height: 8),

          // Tagline
          Center(
            child: Text(
              "Reliable & Quick Cattle Care",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Subheading
          const Text(
            "I need consultation for:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Category Cards
          for (final cat in categories)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ConsultationScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: AssetImage(cat['image']),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        cat['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
