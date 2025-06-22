import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String gender = "Male";
  String state = "Select State"; // Default placeholder for state
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobNoController = TextEditingController();
  final locationController = TextEditingController();
  final ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  void _fetchUserData() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the user document from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        nameController.text = userData['name'] ?? "";
        emailController.text = userData['email'] ?? ""; // email will be displayed but not editable
        mobNoController.text = userData['mobno'] ?? "";
        locationController.text = userData['location'] ?? "";
        ageController.text = userData['age']?.toString() ?? "";
      });
    }
  }

  // Save or update user data in Firestore
  void _updateUserData() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Get data from the text fields
    String updatedName = nameController.text.isNotEmpty ? nameController.text : "";
    String updatedLocation = locationController.text.isNotEmpty ? locationController.text : "";
    String updatedMobNo = mobNoController.text.isNotEmpty ? mobNoController.text : "";
    String updatedAge = ageController.text.isNotEmpty ? ageController.text : "";

    // Update Firestore document
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'name': updatedName,
      'location': updatedLocation,
      'mobno': updatedMobNo,
      'age': updatedAge,
    });

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));

    // Optionally, pop the current screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2E6153),
        title: Center(child: Text("Cattle", style: TextStyle(color: Colors.white))),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Removed profile image and change picture action
              SizedBox(height: 20),
              _buildTextField("Name", nameController, isEditable: true), // Name is editable
              _buildTextField("Email", emailController, isEditable: false), // Email is not editable
              _buildTextField("Mobile No.", mobNoController, isEditable: true), // Mobile No. is now editable in the TextField
              _buildTextField("Age", ageController, isEditable: true), // Age is editable
              SizedBox(height: 10),
              _buildGenderSelection(),
              _buildTextField("Location", locationController, isEditable: true), // Location is editable
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E6153),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                ),
                onPressed: _updateUserData,
                child: Text("Update Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Common widget for creating TextFields
  Widget _buildTextField(String hintText, TextEditingController controller, {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: isEditable, // Make the field editable or non-editable based on `isEditable`
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // Gender selection using choice chips
  Widget _buildGenderSelection() {
    return Row(
      children: [
        Text("Gender", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(width: 20),
        ChoiceChip(
          label: Text("Male"),
          selected: gender == "Male",
          onSelected: (selected) => setState(() => gender = "Male"),
          selectedColor: Colors.teal,
        ),
        SizedBox(width: 10),
        ChoiceChip(
          label: Text("Female"),
          selected: gender == "Female",
          onSelected: (selected) => setState(() => gender = "Female"),
          selectedColor: Colors.teal,
        ),
      ],
    );
  }
}
