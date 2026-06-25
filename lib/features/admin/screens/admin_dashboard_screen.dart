import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/common/app_bottom_nav.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/push_notification_service.dart';
import '../providers/admin_provider.dart';
import '../tabs/overview_tab.dart';
import '../tabs/users_tab.dart';
import '../tabs/hostels_tab.dart';
import '../tabs/revenue_tab.dart';
import '../tabs/settings_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  String? _usersInitialFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().startListening();
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        PushNotificationService.instance.registerUser(user.id);
      }
    });
  }

  static const _navItems = [
    BottomNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: AppStrings.navOverview),
    BottomNavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people_rounded,
        label: AppStrings.navUsers),
    BottomNavItem(
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment_rounded,
        label: AppStrings.navHostels),
    BottomNavItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
        label: 'Revenue'),
    BottomNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: AppStrings.navSettings),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      AdminOverviewTab(onTabChange: (index) {
        setState(() => _currentIndex = index);
      }),
      AdminUsersTab(
        key: _usersInitialFilter != null ? ValueKey(_usersInitialFilter) : null,
        initialFilter: _usersInitialFilter,
      ),
      const AdminHostelsTab(),
      const AdminRevenueTab(),
      AdminSettingsTab(
        onNavigateToUsers: (filter) {
          setState(() {
            _usersInitialFilter = filter;
            _currentIndex = 1;
          });
        },
      ),
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
