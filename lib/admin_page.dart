import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cattle_t/vet_detail_admin_view.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  static const String adminEmail = 'admin12@gmail.com';

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Color _getStatusColor(dynamic status) {
    if (status == true) return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  String _getStatusText(dynamic status) {
    if (status == true) return 'Approved';
    if (status == 'rejected') return 'Rejected';
    return 'Pending';
  }

  Widget _buildVetCard({
    required String name,
    required String email,
    required String vetId,
    required dynamic status,
    required BuildContext context,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.person, size: 28, color: Colors.green.shade800),
        ),
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VetDetailsAdminView(vetId: vetId),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email != adminEmail) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied\nYou are not authorized to view this page.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Approval Dashboard'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'veterinarian')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No veterinarian data found.'));
          }

          final allVets = snapshot.data!.docs;

          final pendingOrRejectedVets = allVets.where((doc) {
            final status = doc['approved'];
            return status != true;
          }).toList();

          final approvedVets = allVets.where((doc) => doc['approved'] == true).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Pending / Rejected
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pending / Rejected Veterinarians',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                  ),
                ),
                if (pendingOrRejectedVets.isEmpty)
                  const Center(child: Text('No pending veterinarian requests.')),
                ...pendingOrRejectedVets.map((vet) {
                  return _buildVetCard(
                    name: vet['name'] ?? 'Unknown',
                    email: vet['email'] ?? 'No email',
                    vetId: vet.id,
                    status: vet['approved'],
                    context: context,
                  );
                }).toList(),

                // Section 2: Approved Vets
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Approved Veterinarians',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                ),
                if (approvedVets.isEmpty)
                  const Center(child: Text('No approved veterinarians yet.')),
                ...approvedVets.map((vet) {
                  return _buildVetCard(
                    name: vet['name'] ?? 'Unknown',
                    email: vet['email'] ?? 'No email',
                    vetId: vet.id,
                    status: vet['approved'],
                    context: context,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
