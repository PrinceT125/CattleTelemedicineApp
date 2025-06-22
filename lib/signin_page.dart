import 'package:cattle_t/CattleOwnerScreen/intropage.dart';

import 'package:cattle_t/VeterinarianScreen/vetUi.dart';
import 'package:cattle_t/VeterinarianScreen/vet_detail_form.dart';
import 'package:cattle_t/admin_page.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';


class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _message = '';
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final email = _emailController.text.trim();

      if (email == 'admin12@gmail.com') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
        );
        return;
      }

      // Fetch user document from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        setState(() => _message = 'User data not found.');
        return;
      }

      final role = userDoc.data()?['role'] ?? '';




      if (role == 'petowner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => IntroPage(uid: uid)),
        );
      } else if (role == 'veterinarian')  {
        // Check if required vet fields are filled
        final data = userDoc.data()!;
        final hasFilledDetails = data.containsKey('phone') &&
            data.containsKey('clinic') &&
            data.containsKey('qualification') &&
            data.containsKey('specialization') &&
            data.containsKey('location') &&
            data.containsKey('license') &&
            data.containsKey('experience');

        if (!hasFilledDetails) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VetDetailsFormPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Vetui(uid: uid)),
          );
        }
      }
      else {
        setState(() => _message = 'Invalid user role.');
      }
    } catch (e) {
      setState(() => _message = 'Login failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Color(0xFF1976D2)),
                SizedBox(height: 16),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[600]),
                ),
                SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Sign In"),
                  ),
                ),
                if (_message.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    _message,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SignUpPage()),
                      ),
                      child: Text("Sign up"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
