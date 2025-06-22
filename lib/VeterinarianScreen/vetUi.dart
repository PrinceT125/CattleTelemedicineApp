
import 'package:cattle_t/VeterinarianScreen/chatlistPage.dart';
import 'package:cattle_t/VeterinarianScreen/home_page.dart';
import 'package:cattle_t/VeterinarianScreen/vetChatpage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../VeterinarianScreen/Settings.dart';

class Vetui extends StatefulWidget {
  final String uid;
  const Vetui({Key? key, required this.uid}) : super(key: key);

  @override
  State<Vetui> createState() => _VetuiState();
}

class _VetuiState extends State<Vetui> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  bool _isApproved = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _isApproved = data?['approved'] == true;
          _pages = [
            HomeContentPage(vetUid: widget.uid),
            ChatListPage(vetUid: widget.uid),
            SettingsPage(),
          ];
        });
      }
    } catch (e) {
      // Default to false on error
      setState(() {
        _isApproved = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) => setState(() => _currentIndex = index);

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If vet is not yet approved
    if (!_isApproved) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Awaiting Approval'),
          backgroundColor: Colors.green[700],
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Your account is awaiting admin approval.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check back later.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cattle Telemedicine'),
        backgroundColor: Colors.green[700],
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
