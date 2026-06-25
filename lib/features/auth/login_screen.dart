import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../student/providers/booking_provider.dart';
import '../student/providers/hostel_provider.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    await authProvider.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: widget.role,
    );

    if (!mounted) return;
    if (authProvider.error != null) return;

    // Ensure data is loaded
    final hostelProvider = context.read<HostelProvider>();
    final bookingProvider = context.read<BookingProvider>();

    await Future.wait([
      hostelProvider.loadHostels(),
      bookingProvider.loadBookings(
        userId: widget.role == UserRole.tenant ? authProvider.user?.id : null,
      ),
    ]);
    await hostelProvider.loadFavorites(authProvider.user!.id);

    // Set city based on user's profile
    if (authProvider.user?.city != null && authProvider.user!.city!.isNotEmpty) {
      hostelProvider.setCity(authProvider.user!.city!);
    }

    if (!mounted) return;

    String route;
    switch (widget.role) {
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
  }

  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController(text: _emailCtrl.text.trim());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;
              await context.read<AuthProvider>().sendPasswordResetEmail(email);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent.')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 40),
                AppTextField(
                  label: AppStrings.email,
                  hint: AppStrings.enterEmail,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.email,
                  prefixIcon: const Icon(Icons.email_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AppStrings.password,
                  hint: AppStrings.enterPassword,
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  validator: AppValidators.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(AppStrings.forgotPassword,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(builder: (_, auth, __) {
                  if (auth.error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(auth.error!,
                        style: const TextStyle(
                            color: AppColors.red, fontSize: 12)),
                  );
                }),
                PrimaryButton(
                  label: AppStrings.login,
                  onPressed: _handleLogin,
                  fullWidth: true,
                  isLoading: isLoading,
                ),
                if (widget.role != UserRole.admin) ...[
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text(AppStrings.noAccount,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed(
                            AppRouter.signup,
                            arguments: widget.role,
                          ),
                      child: const Text(' ${AppStrings.register}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
        child: Column(children: [
      const SizedBox(height: 20),
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(70 * 0.28),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(90 * 0.28),
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(AppStrings.login,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      const Text(AppStrings.enterCreds,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }
}
