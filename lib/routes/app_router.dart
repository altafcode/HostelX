import 'package:flutter/material.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/student/screens/home_screen.dart';
import '../features/student/screens/hostel_details_screen.dart';
import '../features/student/screens/search_screen.dart';
import '../features/student/screens/checkout_screen.dart';
import '../features/student/screens/notification_screen.dart';
import '../features/owner/screens/owner_home_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../domain/entities/booking_entity.dart';
import '../domain/entities/user_entity.dart';
import '../domain/entities/hostel_entity.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String tenantHome = '/tenant';
  static const String hostelDetails = '/hostel';
  static const String search = '/search';
  static const String checkout = '/checkout';
  static const String notifications = '/notifications';
  static const String ownerHome = '/owner';
  static const String adminDashboard = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _slide(const SplashScreen());

      case login:
        final role = settings.arguments as UserRole? ?? UserRole.tenant;
        return _slide(LoginScreen(role: role));

      case signup:
        final role = settings.arguments as UserRole? ?? UserRole.tenant;
        return _slide(SignupScreen(role: role));

      case tenantHome:
        return _fade(const StudentHomeScreen());

      case hostelDetails:
        final hostelId = settings.arguments as String;
        return _slide(HostelDetailsScreen(hostelId: hostelId));

      case search:
        final query = settings.arguments as String? ?? '';
        return _slide(SearchScreen(initialQuery: query));

      case checkout:
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(CheckoutScreen(
          hostel: args['hostel'] as HostelEntity,
          roomType: args['roomType'] as String,
          roomNumber: args['roomNumber'] as String,
          price: args['price'] as int,
          booking: args['booking'] as BookingEntity?,
        ));

      case notifications:
        return _slide(const NotificationScreen());

      case ownerHome:
        return _fade(const OwnerHomeScreen());

      case adminDashboard:
        return _fade(const AdminDashboardScreen());

      default:
        return _slide(const SplashScreen());
    }
  }

  static PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );

  static PageRoute _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      );
}
