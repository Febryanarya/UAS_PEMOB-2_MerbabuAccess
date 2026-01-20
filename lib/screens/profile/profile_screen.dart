import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _updateProfile() async {
    // TODO: Implement update profile functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Profil'),
        content: const Text('Fitur ini akan segera tersedia!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // PROFILE PICTURE
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.green[50],
                child: Text(
                  (_currentUser?.displayName?.isNotEmpty == true 
                      ? _currentUser!.displayName![0].toUpperCase() 
                      : 'U'),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // USER NAME
            Text(
              _currentUser?.displayName ?? 'User Name',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            
            // EMAIL
            Text(
              _currentUser?.email ?? 'user@email.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            
            // VERIFIED BADGE
            if (_currentUser?.emailVerified == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green[700], size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Email Terverifikasi',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
            
            // PROFILE CARD
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('UID', _currentUser?.uid ?? '-'),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Bergabung Sejak',
                      _currentUser?.metadata.creationTime != null
                          ? _currentUser!.metadata.creationTime!
                              .toString()
                              .substring(0, 10)
                          : '-',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Login Terakhir',
                      _currentUser?.metadata.lastSignInTime != null
                          ? _currentUser!.metadata.lastSignInTime!
                              .toString()
                              .substring(0, 10)
                          : '-',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ACTION BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Ubah Profil'),
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.green[50],
                  foregroundColor: Colors.green[700],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Ubah Password'),
                onPressed: () {
                  // TODO: Implement change password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur ubah password akan segera tersedia')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // VERSION INFO
            Text(
              'MerbabuAccess v1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}