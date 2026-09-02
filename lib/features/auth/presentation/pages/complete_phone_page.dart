import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/main_navigation_wrapper.dart';
import 'login_page.dart';

class CompletePhonePage extends StatefulWidget {
  const CompletePhonePage({super.key});

  @override
  State<CompletePhonePage> createState() => _CompletePhonePageState();
}

class _CompletePhonePageState extends State<CompletePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSavePhone() {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    context.read<AuthBloc>().add(AuthUpdatePhoneRequested(phone: phone));
  }

  void _handleSignOut() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Phone number is required to complete your registration.'),
                ),
              ],
            ),
            backgroundColor: AppColors.discountRed,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState.status == AuthStatus.authenticated &&
              authState.currentUser != null &&
              authState.currentUser!.phone.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Phone number verified! Welcome to Cherish.'),
                    ),
                  ],
                ),
                backgroundColor: AppColors.successGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainNavigationWrapper(initialIndex: 0),
              ),
              (route) => false,
            );
          } else if (authState.status == AuthStatus.failure && authState.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(authState.errorMessage!)),
                  ],
                ),
                backgroundColor: AppColors.discountRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, authState) {
          final isLoading = authState.isLoading;
          final user = authState.currentUser;

          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                TextButton.icon(
                  onPressed: isLoading ? null : _handleSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.discountRed),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.discountRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon Header
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.phone_iphone_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Required Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'REQUIRED STEP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'Provide Your Phone Number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A valid phone number is strictly required for order confirmation, delivery coordination, and account security. You cannot skip this step.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: subtextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Info Card
                        if (user != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  backgroundImage: user.avatarUrl.isNotEmpty
                                      ? NetworkImage(user.avatarUrl)
                                      : null,
                                  child: user.avatarUrl.isEmpty
                                      ? Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name.isNotEmpty ? user.name : 'Account Owner',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtextColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.warmAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.pending_outlined, size: 12, color: AppColors.warmAmber),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pending Phone',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warmAmber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Phone Field Label
                        Row(
                          children: [
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '*',
                              style: TextStyle(
                                color: AppColors.discountRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. 012 345 678 or 096 123 4567',
                            hintStyle: TextStyle(
                              color: subtextColor.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: subtextColor,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: surfaceColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.discountRed),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.discountRed, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number (Required)';
                            }
                            final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                            if (digitsOnly.length < 8) {
                              return 'Please enter a valid phone number (at least 8 digits)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _handleSavePhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save & Complete Registration',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Switch/Cancel Account Option
                        Center(
                          child: TextButton(
                            onPressed: isLoading ? null : _handleSignOut,
                            child: Text(
                              'Use a different account / Sign out',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
