import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VetDetailsAdminView extends StatefulWidget {
  final String vetId;

  const VetDetailsAdminView({Key? key, required this.vetId}) : super(key: key);

  @override
  State<VetDetailsAdminView> createState() => _VetDetailsAdminViewState();
}

class _VetDetailsAdminViewState extends State<VetDetailsAdminView> {
  DocumentSnapshot? vetData;
  bool isLoading = true;
  bool hasAllRequiredFields = false;

  final List<String> requiredFields = [
    'name',
    'email',
    'phone',
    'clinic',
    'qualification',
    'specialization',
    'location',
    'license',
    'experience',
  ];

  @override
  void initState() {
    super.initState();
    _loadVetData();
  }

  Future<void> _loadVetData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.vetId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      final allFieldsPresent = requiredFields.every((field) =>
      data.containsKey(field) && data[field] != null && data[field].toString().trim().isNotEmpty);

      setState(() {
        vetData = doc;
        hasAllRequiredFields = allFieldsPresent;
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(dynamic status) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.vetId).update({
      'approved': status,
    });
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = vetData!.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Veterinarian Details"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetail("Name", data['name']),
            _buildDetail("Email", data['email']),
            _buildDetail("Phone", data['phone']),
            _buildDetail("Clinic", data['clinic']),
            _buildDetail("Qualification", data['qualification']),
            _buildDetail("Specialization", data['specialization']),
            _buildDetail("Location", data['location']),
            _buildDetail("License Number", data['license']),
            _buildDetail("Experience", data['experience'] != null ? "${data['experience']} years" : null),
            _buildDetail("Status", data['approved']?.toString()),

            const SizedBox(height: 30),

            if (!hasAllRequiredFields) ...[
              const Text(
                "⚠️ Cannot approve or reject this veterinarian until all required details are filled.",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(true),
                    icon: const Icon(Icons.check),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus("rejected"),
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value?.toString().trim().isNotEmpty == true ? value.toString() : 'Not provided'),
      ),
    );
  }
}
