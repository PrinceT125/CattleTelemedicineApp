
import 'package:cattle_t/CattleOwnerScreen/Farmer_Profile.dart';
import 'package:cattle_t/CattleOwnerScreen/cattleRecord.dart';
import 'package:cattle_t/CattleOwnerScreen/petownerChatpage.dart';
import 'package:cattle_t/signin_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  final String userUid = FirebaseAuth.instance.currentUser!.uid; // Get the current user's UID

  Future<Map<String, dynamic>> _fetchUserData() async {
    try {
      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid) // Get the document based on the user's UID
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return {};
    }
  }
  // final String

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header with Profile Picture and Name
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const UserAccountsDrawerHeader(
                  accountName: Text('Loading...'),
                  accountEmail: Text('Loading...'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                  ),
                );
              }

              if (snapshot.hasError) {
                return const UserAccountsDrawerHeader(
                  accountName: Text('Error'),
                  accountEmail: Text('Error fetching data'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.error),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                  ),
                );
              }

              // Extract the user data from snapshot
              Map<String, dynamic> userData = snapshot.data ?? {};
              String userName = userData['name'] ?? 'Unknown User';
              String userEmail = userData['email'] ?? 'No email available';
              String profileImageUrl = userData['profileImageUrl'] ?? ''; // Make sure the Firestore doc has this field

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: UserAccountsDrawerHeader(
                  accountName: Text(userName),
                  accountEmail: Text(userEmail),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.green, // You can change this color
                    child:
                    Icon(
                      Icons.person, // Icon to display when no profile image
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),

          // Drawer Menu Items
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              // Handle home navigation
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.pets),
            title: Text('Cattle Records'),
            onTap: () {
              // Handle cattle health navigation
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Cattlerecord()),
              ); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.medical_services),
            title: Text('Virtual Consultation'),
            onTap: () {
              // Handle virtual consultation navigation
              String petOwnerUid = FirebaseAuth.instance.currentUser!.uid;

              // Handle virtual consultation navigation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListPage(petOwnerUid: petOwnerUid),
                ),
              );  // Close the drawer
            },
          ),

          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInPage()), // Navigate to SignInPage
              );
            },
          )
        ],
      ),
    );
  }
}
