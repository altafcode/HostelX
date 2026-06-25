import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/student/providers/booking_provider.dart';
import '../features/student/providers/hostel_provider.dart';
import '../features/student/providers/student_provider.dart';
import '../features/admin/providers/admin_provider.dart';
import '../features/owner/providers/owner_provider.dart';
import 'auth_provider.dart';
import 'navigation_provider.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HostelProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: child,
    );
  }
}
