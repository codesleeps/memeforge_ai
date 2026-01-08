import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './services/supabase_service.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    SupabaseService.instance.authStateChanges.listen((event) {
      debugPrint('Auth state changed: ${event.session?.user?.email}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'MemeForge AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: _getInitialRoute(),
          routes: AppRoutes.routes,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }

  String _getInitialRoute() {
    // Check if user is already authenticated
    try {
      final isAuthenticated = SupabaseService.instance.isAuthenticated;
      return isAuthenticated ? AppRoutes.homeDashboard : AppRoutes.loginScreen;
    } catch (e) {
      // If Supabase is not initialized, go to login screen
      debugPrint('Supabase not initialized, going to login: $e');
      return AppRoutes.loginScreen;
    }
  }
}
