import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ TAMBAH INI
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/detail_paket_screen.dart';
import 'screens/booking/booking_form_screen.dart';
import 'screens/booking/riwayat_booking_screen.dart';
import 'screens/booking/cart_screen.dart';
import 'screens/booking/checkout_screen.dart';
import 'screens/booking/ticket_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/weather/weather_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'models/paket_pendakian.dart';
import 'models/booking_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INISIALISASI FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ INISIALISASI FORMAT TANGGAL INDONESIA (FIX ERROR)
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MerbabuAccessApp());
}

class MerbabuAccessApp extends StatelessWidget {
  const MerbabuAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MerbabuAccess',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.detailPaket: (context) {
            final paket = ModalRoute.of(context)!.settings.arguments as PaketPendakian;
            return DetailPaketScreen(paket: paket);
          },
          AppRoutes.bookingForm: (context) {
            final paket = ModalRoute.of(context)!.settings.arguments as PaketPendakian;
            return BookingFormScreen(paket: paket);
          },
          AppRoutes.riwayatBooking: (context) => const RiwayatBookingScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.weather: (context) => const WeatherScreen(),
          AppRoutes.cart: (context) => const CartScreen(),
          AppRoutes.checkout: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return CheckoutScreen(args: args as Map<String, dynamic>?);
          },
          AppRoutes.ticket: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args == null || args is! Booking) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Error'),
                  backgroundColor: Colors.red,
                ),
                body: const Center(
                  child: Text('Data tiket tidak valid'),
                ),
              );
            }
            return TicketScreen(booking: args);
          },
        },
        // Optimasi untuk mencegah text scaling issues
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
            ),
            child: child!,
          );
        },
        // Error handler untuk route yang tidak ditemukan
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Halaman Tidak Ditemukan'),
                backgroundColor: Colors.red,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(
                      'Route "${settings.name}" tidak ditemukan',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Kembali ke Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}