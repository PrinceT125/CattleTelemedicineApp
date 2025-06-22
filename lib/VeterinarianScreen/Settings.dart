import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  String? _approvalStatus;

  @override
  void initState() {
    super.initState();
    _loadVetInfo();
  }

  Future<void> _loadVetInfo() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _approvalStatus = data['approved'] == true
              ? 'Approved'
              : (data['approved'] == 'rejected' ? 'Rejected' : 'Pending');
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _auth.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // Profile Picture Placeholder
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green[100],
                child: const Icon(Icons.person, size: 50, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),

            // Name Field
            _buildTextField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person,
              readOnly: false,
            ),

            const SizedBox(height: 20),

            // Email Field (read-only)
            _buildTextField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email,
              readOnly: true,
            ),

            const SizedBox(height: 20),

            // Approval Status
            if (_approvalStatus != null)
              Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Approval Status: $_approvalStatus',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // Change Password
            TextButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset, color: Colors.green),
              label: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
