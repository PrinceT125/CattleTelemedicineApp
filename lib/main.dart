// import 'package:cattle_t/CattleOwnerScreen/C_listScreen.dart';
// import 'package:cattle_t/CattleOwnerScreen/CaProfile_Page.dart';
// import 'package:cattle_t/CattleOwnerScreen/edit.dart';
import 'package:cattle_t/CattleOwnerScreen/intropage.dart';

import 'package:cattle_t/VeterinarianScreen/vetUi.dart';
import 'package:cattle_t/admin_page.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signin_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String adminEmail = 'admin12@gmail.com';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading state while waiting for auth state
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            // Fetch role from Firestore for the logged in user
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  // If user doc not found, fallback to sign in page or show error
                  return SignInPage();
                }

                final data = userSnapshot.data!.data() as Map<String, dynamic>;
                final role = data['role'] ?? '';

                if (role == 'petowner') {
                  return IntroPage(uid: user.uid);
                } else if (role == 'veterinarian') {
                  return Vetui(uid: user.uid);
                } else {
                  // Unknown role fallback
                  return SignInPage();
                }
              },
            );
          } else {
            // Not logged in, show sign-in page
            return SignInPage();
          }
        },
      ),
      routes: {
        '/login': (context) => SignInPage(),
        '/admin': (context) => const AdminPage(),
        // 'a': (context) => CattleListPage(),
        // // 'b': (context) => AddCattlePage(),
        // 'c': (context) => CattleProfilePage(),
        // 'd': (context) => ConsultationBookingPage(),
        // 'e': (context) => PaymentPage(),
        // 'f': (context) => ConsultationConfirmationPage(),
        // 'g': (context) => ConsultationPage(),
        VideoCallPage.routeName: (context) => VideoCallPage(),
        ConsultationHistoryPage.routeName: (context) => ConsultationHistoryPage(),

      },


    );
  }
}
class VideoCallPage extends StatelessWidget {
  static const routeName = '/video-call';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Consultation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Connecting with ',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simulate ending the call
                Navigator.pop(context);
              },
              child: Text('End Call'),
            ),
          ],
        ),
      ),
    );
  }
}

// Page for Consultation History
class ConsultationHistoryPage extends StatelessWidget {
  static const routeName = '/consultation-history';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consultation History'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Consultation with Farmer Joe'),
            subtitle: Text('Cattle #42 - Diagnosis: Healthy'),
          ),
          ListTile(
            title: Text('Consultation with Farmer Anne'),
            subtitle: Text('Cattle #57 - Diagnosis: Mild Fever'),
          ),
        ],
      ),
    );
  }
}

