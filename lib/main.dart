import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
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
import 'models/paket_pendakian.dart';
import 'models/booking_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MerbabuAccessApp());
}

class MerbabuAccessApp extends StatelessWidget {
  const MerbabuAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MerbabuAccess',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: {
        // AUTH ROUTES
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        
        // HOME ROUTES
        AppRoutes.home: (context) => const HomeScreen(),
        
        // DETAIL PAKET ROUTE
        AppRoutes.detailPaket: (context) {
          final paket = ModalRoute.of(context)!.settings.arguments as PaketPendakian;
          return DetailPaketScreen(paket: paket);
        },
        
        // BOOKING FORM ROUTE
        AppRoutes.bookingForm: (context) {
          final paket = ModalRoute.of(context)!.settings.arguments as PaketPendakian;
          return BookingFormScreen(paket: paket);
        },
        
        // RIWAYAT BOOKING ROUTE
        AppRoutes.riwayatBooking: (context) => const RiwayatBookingScreen(),
        
        // PROFILE ROUTE
        AppRoutes.profile: (context) => const ProfileScreen(),

        // WEATHER ROUTE
        AppRoutes.weather: (context) => const WeatherScreen(),

        // CART ROUTE
        AppRoutes.cart: (context) => const CartScreen(),

        // CHECKOUT ROUTE
        AppRoutes.checkout: (context) => const CheckoutScreen(),

        // TICKET ROUTE (DENGAN PARAMETER)
        AppRoutes.ticket: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args == null || args is! Booking) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Data tiket tidak valid')),
            );
          }
          return TicketScreen(booking: args);
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} tidak ditemukan'),
            ),
          ),
        );
      },
    );
  }
}