import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/paket_service.dart';
import '../../models/paket_pendakian.dart';
import '../../core/routes/app_routes.dart';
import '../profile/profile_screen.dart';
import '../weather/weather_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PaketPendakian>> _paketFuture;
  final PaketService _paketService = PaketService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _paketFuture = _paketService.fetchPaketPendakian();
    _currentUser = _auth.currentUser;
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MerbabuAccess'),
        actions: [
          // ✅ ICON RIWAYAT BOOKING
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.riwayatBooking);
            },
            tooltip: 'Riwayat Booking',
          ),
        ],
      ),
      // ✅ DRAWER MENU
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUser?.displayName ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                _currentUser?.email ?? 'user@email.com',
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (_currentUser?.displayName?.isNotEmpty == true 
                      ? _currentUser!.displayName![0].toUpperCase() 
                      : 'U'),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.green[700],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.green),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.green),
              title: const Text('Riwayat Booking'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.riwayatBooking);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            // ✅ TAMBAH MENU CUACA MERBABU DI SINI
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.blue),
              title: const Text('Cuaca Merbabu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.weather);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<PaketPendakian>>(
        future: _paketFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data paket'));
          }

          final paketList = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paketList.length,
            itemBuilder: (context, index) {
              final paket = paketList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      paket.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image),
                        );
                      },
                    ),
                  ),
                  title: Text(paket.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rute: ${paket.route}'),
                      Text('Durasi: ${paket.duration}'),
                      Text('Kuota: ${paket.quota} orang'),
                      Text(
                        'Harga: Rp ${paket.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.detailPaket,
                      arguments: paket,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}