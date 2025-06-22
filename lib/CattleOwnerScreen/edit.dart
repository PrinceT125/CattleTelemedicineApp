// add_edit_cattle.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cattleRecord.dart';
import 'StartConsultation.dart'; // For Cattle model

class AddCattlePage extends StatefulWidget {
  @override
  _AddCattlePageState createState() => _AddCattlePageState();
}

class _AddCattlePageState extends State<AddCattlePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final ageController = TextEditingController();
  final descriptionController = TextEditingController();
  String gender = 'Male';

  Future<void> _saveCattle() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = {
        'name': nameController.text.trim(),
        'breed': breedController.text.trim(),
        'age': ageController.text.trim(),
        'gender': gender,
        'description': descriptionController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('owners')
          .doc(user.uid)
          .collection('cattle')
          .add(data);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Cattle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, "Name"),
              _buildTextField(breedController, "Breed"),
              _buildTextField(ageController, "Age"),
              _buildGenderDropdown(),
              _buildTextField(descriptionController, "Description", maxLines: 3),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCattle,
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: gender,
        items: ['Male', 'Female']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => setState(() => gender = value!),
        decoration: InputDecoration(
          labelText: "Gender",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class EditCattlePage extends StatefulWidget {
  final Cattle cattle;

  EditCattlePage({required this.cattle});

  @override
  _EditCattlePageState createState() => _EditCattlePageState();
}

class _EditCattlePageState extends State<EditCattlePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late TextEditingController descriptionController;
  late String gender;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.cattle.name);
    breedController = TextEditingController(text: widget.cattle.breed);
    ageController = TextEditingController(text: widget.cattle.age);
    descriptionController =
        TextEditingController(text: widget.cattle.description);
    gender = widget.cattle.gender;
  }

  Future<void> _updateCattle() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = {
        'name': nameController.text.trim(),
        'breed': breedController.text.trim(),
        'age': ageController.text.trim(),
        'gender': gender,
        'description': descriptionController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('owners')
          .doc(user.uid)
          .collection('cattle')
          .doc(widget.cattle.docId)
          .update(data);

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Cattle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(nameController, "Name"),
              _buildTextField(breedController, "Breed"),
              _buildTextField(ageController, "Age"),
              _buildGenderDropdown(),
              _buildTextField(descriptionController, "Description", maxLines: 3),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateCattle,
                child: Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: gender,
        items: ['Male', 'Female']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => setState(() => gender = value!),
        decoration: InputDecoration(
          labelText: "Gender",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
