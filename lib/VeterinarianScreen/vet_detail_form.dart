import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../VeterinarianScreen/vetUi.dart'; // Make sure this import is correct

class VetDetailsFormPage extends StatefulWidget {
  const VetDetailsFormPage({Key? key}) : super(key: key);

  @override
  _VetDetailsFormPageState createState() => _VetDetailsFormPageState();
}

class _VetDetailsFormPageState extends State<VetDetailsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'clinic': _clinicController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'location': _locationController.text.trim(),
      'license': _licenseController.text.trim(),
      'experience': _experienceController.text.trim(),
      'role': 'veterinarian',
      'approved': false,
    };

    try {
      await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Details saved successfully! Awaiting approval.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Vetui(uid: user.uid)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType inputType = TextInputType.text,
        bool readOnly = false,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        validator: validator ?? (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinarian Details'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Full Name', Icons.person),
              _buildTextField(
                _emailController,
                'Email Address',
                Icons.email,
                readOnly: true,
              ),
              _buildTextField(
                _phoneController,
                'Phone Number',
                Icons.phone,
                inputType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Phone is required';
                  if (value.trim().length < 10) return 'Invalid phone number';
                  return null;
                },
              ),
              _buildTextField(_clinicController, 'Clinic/Hospital Name', Icons.local_hospital),
              _buildTextField(_qualificationController, 'Qualification', Icons.school),
              _buildTextField(_specializationController, 'Specialization', Icons.pets),
              _buildTextField(_locationController, 'Location', Icons.location_on),
              _buildTextField(_licenseController, 'License Number', Icons.badge),
              _buildTextField(
                _experienceController,
                'Years of Experience',
                Icons.timeline,
                inputType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Experience is required';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Submit Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
