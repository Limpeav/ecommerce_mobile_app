import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../constants/app_colors.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/widgets/google_sign_in_button.dart';

class AuthGuard {
  static void requireAuth(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onAuthenticated,
  }) {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state.isAuthenticated) {
      onAuthenticated();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Lock Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subtextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Google Sign In Button
              GoogleSignInButton(
                text: 'Continue with Google',
                onSuccess: () {
                  Navigator.of(sheetContext).pop();
                  onAuthenticated();
                },
              ),
              const SizedBox(height: 14),

              // Divider OR
              Row(
                children: [
                  Expanded(child: Divider(color: borderColor, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: borderColor, thickness: 1)),
                ],
              ),
              const SizedBox(height: 14),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );

                    if (context.mounted && context.read<AuthBloc>().state.isAuthenticated) {
                      onAuthenticated();
                    }
                  },
                  child: const Text(
                    'Sign In with Email',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterPage(),
                      ),
                    );

                    if (context.mounted && context.read<AuthBloc>().state.isAuthenticated) {
                      onAuthenticated();
                    }
                  },
                  child: const Text(
                    'Create an Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Continue Browsing / Cancel
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  'Continue Browsing',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
