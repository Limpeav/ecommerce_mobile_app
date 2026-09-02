import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/main_navigation_wrapper.dart';
import '../widgets/google_sign_in_button.dart';
import 'complete_phone_page.dart';
import 'login_page.dart';
import 'verify_account_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthBloc>().state;
        if (auth.isAuthenticated) {
          final needsPhone = auth.currentUser?.phone.trim().isEmpty == true;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => needsPhone
                  ? const CompletePhonePage()
                  : const MainNavigationWrapper(initialIndex: 0),
            ),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and privacy policy to continue'),
          backgroundColor: AppColors.warmAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final registeredEmail = _emailController.text.trim();
    final registeredPassword = _passwordController.text;

    context.read<AuthBloc>().add(AuthRegisterRequested(
      name: _nameController.text.trim(),
      email: registeredEmail,
      phone: _phoneController.text.trim(),
      password: registeredPassword,
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
        if (authState.status == AuthStatus.unauthenticated && authState.extraData != null) {
          final registeredEmail = _emailController.text.trim();
          final registeredPassword = _passwordController.text;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Account created! Please verify your email with the 6-digit code.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VerifyAccountPage(
                email: registeredEmail,
                password: registeredPassword,
              ),
            ),
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join our store for fast checkout, exclusive deals and rewards',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: subtextColor, size: 20),
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
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email Address
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        const Text(
                          '(@gmail.com required)',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'yourname@gmail.com',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: Icon(Icons.email_outlined, color: subtextColor, size: 20),
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
                        if (val == null || val.trim().isEmpty) return 'Please enter your email';
                        if (!val.trim().toLowerCase().endsWith('@gmail.com')) {
                          return 'Registration requires a @gmail.com address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 4),
                            const Text('*', style: TextStyle(color: AppColors.discountRed, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const Text(
                          '(Required)',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '0961234567 or 012345678',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: Icon(Icons.phone_outlined, color: subtextColor, size: 20),
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
                        if (val == null || val.trim().isEmpty) return 'Phone number is required for registration';
                        final digits = val.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 8) return 'Please enter a valid phone number (at least 8 digits)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Min 6 chars with uppercase & symbol (e.g. Pass123!)',
                        hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.6), fontSize: 13),
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
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        if (!val.contains(RegExp(r'[A-Z]'))) {
                          return 'Password must contain at least 1 uppercase letter';
                        }
                        if (!val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                          return 'Password must contain at least 1 special character (!@#...)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Re-enter password',
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
                    const SizedBox(height: 20),

                    // Terms and Conditions checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeTerms,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'I agree to the Terms of Service & Privacy Policy',
                            style: TextStyle(fontSize: 13, color: subtextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
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
                              'Create Account',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Divider OR
                    Row(
                      children: [
                        Expanded(child: Divider(color: borderColor, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: borderColor, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Google Sign In Button
                    const GoogleSignInButton(
                      text: 'Sign up with Google',
                    ),
                    const SizedBox(height: 20),

                    // Switch to Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(color: subtextColor, fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
