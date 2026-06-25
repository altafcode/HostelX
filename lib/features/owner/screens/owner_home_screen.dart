import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/app_bottom_nav.dart';
import '../../../providers/auth_provider.dart';
import '../../student/providers/booking_provider.dart';
import '../../student/providers/hostel_provider.dart';
import '../../../data/services/push_notification_service.dart';
import '../providers/owner_provider.dart';
import '../tabs/owner_dashboard_tab.dart';
import '../tabs/my_listings_tab.dart';
import '../tabs/owner_tenants_tab.dart';
import '../tabs/owner_earnings_tab.dart';
import '../tabs/owner_more_tab.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOwnerHomeData();
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        PushNotificationService.instance.registerUser(user.id);
      }
    });
  }

  Future<void> _loadOwnerHomeData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final hostelProvider = context.read<HostelProvider>();
    if (hostelProvider.allHostels.isEmpty) {
      await hostelProvider.loadHostels();
    }

    if (!mounted) return;
    await context.read<OwnerProvider>().loadOwnerData(user.id);

    if (!mounted) return;
    final hostelIds = hostelProvider.allHostels
        .where((h) => h.ownerId == user.id || h.ownerName == user.name)
        .map((h) => h.id)
        .toList();

    final bookingProvider = context.read<BookingProvider>();
    if (hostelIds.isEmpty) {
      bookingProvider.stopWatchingBookings(clearBookings: true);
    } else {
      bookingProvider.watchBookings(hostelIds: hostelIds);
    }
  }

  static const _navItems = [
    BottomNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard'),
    BottomNavItem(
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment_rounded,
        label: 'Listings'),
    BottomNavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people_rounded,
        label: 'Tenants'),
    BottomNavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Revenue'),
    BottomNavItem(
        icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz_rounded,
        label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      OwnerDashboardTab(onTabChange: (i) => setState(() => _currentIndex = i)),
      const MyListingsTab(),
      const OwnerTenantsTab(),
      const OwnerRevenueTab(),
      OwnerMoreTab(onTabChange: (i) => setState(() => _currentIndex = i)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tabs[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
    );
  }
}
