import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seller_ecommerce/services/fcm_service.dart';
import 'providers/cart_provider.dart';
import 'providers/address_provider.dart';
import 'providers/location_provider.dart';
import 'providers/product_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMService().initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'Seller - Quản lý cửa hàng',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          primaryColor: AppTheme.primaryColor,
          scaffoldBackgroundColor: AppTheme.backgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryColor,
            secondary: AppTheme.secondaryColor,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    // If logged in, register FCM token
    if (isLoggedIn) {
      await _registerFCMToken();
    }
  }

  Future<void> _registerFCMToken() async {
    try {
      // Get device info
      final deviceType = Theme.of(context).platform == TargetPlatform.iOS ? 'iOS' : 'Android';
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await FCMService().registerToken(
        deviceType: deviceType,
        deviceId: deviceId,
      );
      print('FCM token registered successfully');
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  Future<void> _checkShopStatus() async {
    // Removed - shop check now handled in seller_dashboard_screen
  }

  Future<void> _navigateToCreateShop() async {
    // Removed - navigate to create shop now handled in seller_dashboard_screen
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth
    if (_isLoggedIn == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // Not logged in -> show login screen
    if (!_isLoggedIn!) {
      return const LoginScreen();
    }

    // Logged in -> show main screen (shop check handled in dashboard)
    return const MainNavigationScreen();
  }
}
