import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/paket_service.dart';
import '../../models/paket_pendakian.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../booking/riwayat_booking_screen.dart';
import '../profile/profile_screen.dart';
import '../weather/weather_screen.dart';
import 'home_content.dart';

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
  
  int _selectedIndex = 0;
  
  // ✅ SIMPLE SCREEN LIST
  final List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _paketFuture = _paketService.fetchPaketPendakian();
    _currentUser = _auth.currentUser;
    
    // ✅ INITIALIZE SCREENS
    _widgetOptions.addAll([
      const HomeContent(),
      const RiwayatBookingScreen(), // ✅ TANPA CALLBACK LAGI
      const ProfileScreen(),
    ]);
    
    // Load cart count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCartCount();
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terrain, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'MerbabuAccess',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return IconButton(
                icon: Badge(
                  label: Text('${cartProvider.itemCount}'),
                  isLabelVisible: cartProvider.itemCount > 0,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  smallSize: 18,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.cart);
                },
                tooltip: 'Keranjang',
              );
            },
          ),
          
          IconButton(
            icon: Badge(
              label: const Text('2'),
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              smallSize: 18,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Fitur notifikasi akan segera hadir'),
                  backgroundColor: AppTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            tooltip: 'Notifikasi',
          ),
        ],
      ),
      
      drawer: _buildDrawer(),
      
      // ✅ GUNAKAN IndexedStack
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.weather);
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.cloud, size: 28),
        tooltip: 'Cuaca Merbabu',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_filled),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
            ),
            iconSize: 24,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      elevation: 8,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      (_currentUser?.displayName?.isNotEmpty == true 
                          ? _currentUser!.displayName![0].toUpperCase() 
                          : _currentUser?.email?.isNotEmpty == true
                              ? _currentUser!.email![0].toUpperCase()
                              : 'U'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUser?.displayName ?? 'User Merbabu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser?.email ?? 'user@merbabuaccess.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_filled,
                  label: 'Beranda',
                  isActive: _selectedIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'Riwayat Booking',
                  isActive: _selectedIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person,
                  label: 'Profil Saya',
                  isActive: _selectedIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedIndex = 2);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.cloud_outlined,
                  activeIcon: Icons.cloud,
                  label: 'Cuaca Merbabu',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.weather);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  label: 'Keranjang Saya',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.cart);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Pengaturan',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Fitur pengaturan akan segera hadir'),
                        backgroundColor: AppTheme.infoColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 20, thickness: 1),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red, size: 22),
              title: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: _logout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: Colors.red.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(height: 20),
                Text(
                  'MerbabuAccess v1.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your Gateway to Mount Merbabu',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ListTile(
      leading: Icon(
        isActive ? activeIcon : icon,
        color: isActive ? AppTheme.primaryColor : Colors.grey[700],
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? AppTheme.primaryColor : Colors.grey[800],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
    );
  }
}