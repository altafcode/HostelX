import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../routes/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../student/providers/hostel_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showRoleSelection = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Try to restore Firebase session
    final authProvider = context.read<AuthProvider>();  // add: import '../../providers/auth_provider.dart';
    final user = await authProvider.restoreSession();

    if (!mounted) return;

    if (user != null) {
      // Set city based on user's profile
      if (user.city != null && user.city!.isNotEmpty) {
        if (mounted) {
          context.read<HostelProvider>().setCity(user.city!);
        }
      }

      // User already logged in — redirect based on role
      String route;
      switch (user.role) {
        case UserRole.tenant:
          route = AppRouter.tenantHome;
          break;
        case UserRole.owner:
          route = AppRouter.ownerHome;
          break;
        case UserRole.admin:
          route = AppRouter.adminDashboard;
          break;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } else {
      // Not logged in — show role selection
      setState(() => _showRoleSelection = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/background.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _showRoleSelection ? _buildRoleSelection() : _buildLogoSplash(),
      ),
    );
  }

  Widget _buildLogoSplash() {
    return Center(
      key: const ValueKey('logo_splash'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          _buildLogoIcon(size: 80),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Hostel',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                TextSpan(
                  text: 'X',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), letterSpacing: -0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find your home away from home',
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Container(
      key: const ValueKey('role_selection'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          _buildLogoIcon(size: 70),
          const SizedBox(height: 12),
          const Text(
            'Welcome Back!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your role to continue',
            style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 48),
          _RoleCard(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBgColor: const Color(0xFFEFF6FF),
            title: 'Tenant',
            subtitle: 'Find and book hostels',
            onTap: () => Navigator.of(context).pushNamed(AppRouter.login, arguments: UserRole.tenant),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.apartment_rounded,
            iconColor: const Color(0xFF10B981),
            iconBgColor: const Color(0xFFECFDF5),
            title: 'Hostel Owner',
            subtitle: 'Manage your hostels',
            onTap: () => Navigator.of(context).pushNamed(AppRouter.login, arguments: UserRole.owner),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFFF59E0B),
            iconBgColor: const Color(0xFFFFFBEB),
            title: 'Admin',
            subtitle: 'System administration',
            onTap: () => Navigator.of(context).pushNamed(AppRouter.login, arguments: UserRole.admin),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoIcon({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
            blurRadius: 35,
            spreadRadius: 4,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/background.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
