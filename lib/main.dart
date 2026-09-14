import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/wishlist_provider.dart';
import 'core/providers/language_provider.dart';
import 'features/navigation/main_navigation_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CCTVCustomerApp());
}

class CCTVCustomerApp extends StatefulWidget {
  const CCTVCustomerApp({super.key});

  @override
  State<CCTVCustomerApp> createState() => _CCTVCustomerAppState();
}

class _CCTVCustomerAppState extends State<CCTVCustomerApp> {
  @override
  void initState() {
    super.initState();
    // Initialize live Push Notifications via Socket.io
    NotificationService.initialize(scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: 'SK Technology CCTV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
