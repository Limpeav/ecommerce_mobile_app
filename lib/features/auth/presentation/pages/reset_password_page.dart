import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _verifiedResetToken;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyAndReset() async {
    if (!_formKey.currentState!.validate()) return;

    final authBloc = context.read<AuthBloc>();

    // Step 1: If reset token is not yet obtained from OTP code, verify code first
    String resetToken = _verifiedResetToken ?? _codeController.text.trim();
    
    if (_verifiedResetToken == null) {
      try {
        final verifyResult = await authBloc.authRepository.verifyResetCode(
          widget.email,
          _codeController.text.trim(),
        );

        resetToken = (verifyResult['resetToken'] ?? verifyResult['token'] ?? _codeController.text.trim()).toString();
        _verifiedResetToken = resetToken;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.discountRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    // Step 2: Reset the password via AuthBloc
    authBloc.add(AuthResetPasswordRequested(
      token: resetToken,
      newPassword: _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated &&
            authState.successMessage?.toLowerCase().contains('password reset') == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
                  SizedBox(width: 10),
                  Text('Password Reset!'),
                ],
              ),
              content: const Text(
                'Your password has been successfully updated. You can now log in with your new credentials.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          );
        } else if (authState.status == AuthStatus.failure && authState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.errorMessage!),
              backgroundColor: AppColors.discountRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, authState) {
        final isLoading = authState.isLoading;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set New Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit code sent to ${widget.email} and configure your new password.',
                      style: TextStyle(fontSize: 14, color: subtextColor, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Verification Code
                    Text('Verification Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor, fontSize: 16, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: '123456',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), letterSpacing: 0),
                        prefixIcon: Icon(Icons.pin_outlined, color: subtextColor, size: 20),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter the 6-digit code' : null,
                    ),
                    const SizedBox(height: 20),

                    // New Password
                    Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Minimum 6 characters',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: subtextColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: subtextColor,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    Text('Confirm New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: subtextColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: subtextColor,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleVerifyAndReset,
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
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
