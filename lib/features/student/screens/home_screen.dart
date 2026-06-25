import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/navigation_provider.dart';
import '../../../widgets/common/app_bottom_nav.dart';
import '../../../data/services/push_notification_service.dart';
import '../providers/booking_provider.dart';
import '../providers/hostel_provider.dart';
import '../widgets/home/home_tab.dart';
import 'favorites_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  static const _navItems = [
    BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: AppStrings.navHome),
    BottomNavItem(
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        label: AppStrings.navSaved),
    BottomNavItem(
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt_rounded,
        label: AppStrings.navBookings),
    BottomNavItem(
        icon: Icons.person_outlined,
        activeIcon: Icons.person_rounded,
        label: AppStrings.navProfile),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hostelProvider = context.read<HostelProvider>();
      if (hostelProvider.allHostels.isEmpty) {
        hostelProvider.loadHostels();
      }
      final bookingProvider = context.read<BookingProvider>();
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id;
      if (userId != null) {
        bookingProvider.watchBookings(userId: userId);
        PushNotificationService.instance.registerUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProv = context.watch<NavigationProvider>();
    
    final tabs = [
      const HomeTab(),
      const FavoritesScreen(),
      const BookingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: navProv.currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: navProv.currentIndex,
        onTap: (i) => navProv.setIndex(i),
        items: _navItems,
      ),
    );
  }
}
