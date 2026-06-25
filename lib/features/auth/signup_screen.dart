import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../student/providers/hostel_provider.dart';

class SignupScreen extends StatefulWidget {
  final UserRole role;
  const SignupScreen({super.key, this.role = UserRole.tenant});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _selectedCity;
  Occupation _selectedOccupation = Occupation.student;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final hostelProvider = context.read<HostelProvider>();

    await authProvider.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      city: _selectedCity ?? 'Lahore',
      role: widget.role,
      occupation: _selectedOccupation,
    );

    if (!mounted) return;
    if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!), backgroundColor: Colors.red),
      );
      return;
    }

    // Set initial city filter based on user's city
    if (_selectedCity != null) {
      hostelProvider.setCity(_selectedCity!);
    }

    // Registration success — go to correct home
    String route = widget.role == UserRole.owner 
        ? AppRouter.ownerHome 
        : AppRouter.tenantHome;
        
    Navigator.of(context).pushNamedAndRemoveUntil(
      route, (_) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    if (widget.role == UserRole.admin) {
      return const Scaffold(
        body: Center(
          child: Text('Admin registration is not allowed.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
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
                Center(
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
                      borderRadius: BorderRadius.circular(70 * 0.28),
                      child: Image.asset(
                        'assets/images/background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(AppStrings.register,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text(AppStrings.createAccount,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ])),
                const SizedBox(height: 40),
                AppTextField(
                  label: AppStrings.fullName,
                  hint: AppStrings.enterName,
                  controller: _nameCtrl,
                  validator: (v) => AppValidators.required(v, 'Full name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      size: 20, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
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
                  label: AppStrings.phone,
                  hint: AppStrings.enterPhone,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.phone,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      size: 20, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: AppStrings.password,
                  hint: AppStrings.createPassword,
                  controller: _passwordCtrl,
                  obscureText: true,
                  validator: AppValidators.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'City',
                  value: _selectedCity,
                  items: AppConstants.cities,
                  onChanged: (v) => setState(() => _selectedCity = v),
                  hint: 'Select your city',
                  icon: Icons.location_city_rounded,
                ),
                const SizedBox(height: 16),
                _buildDropdown<Occupation>(
                  label: 'Occupation',
                  value: _selectedOccupation,
                  items: Occupation.values,
                  itemLabel: (o) => _formatEnum(o.name),
                  onChanged: (v) => setState(() => _selectedOccupation = v!),
                  hint: 'Select occupation',
                  icon: Icons.work_outline_rounded,
                ),
                const SizedBox(height: 24),
          PrimaryButton(
            label: AppStrings.register,
            onPressed: _handleRegister,
            fullWidth: true,
            isLoading: context.watch<AuthProvider>().isLoading,
          ),
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text(AppStrings.haveAccount,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(' ${AppStrings.login}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String? hint,
    IconData? icon,
    String Function(T)? itemLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel != null ? itemLabel(item) : item.toString(),
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select $label' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: AppColors.textMuted)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  String _formatEnum(String name) {
    final res = name.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}');
    return res[0].toUpperCase() + res.substring(1).toLowerCase();
  }
}
