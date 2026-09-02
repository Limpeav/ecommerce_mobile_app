import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/main_navigation_wrapper.dart';
import 'complete_phone_page.dart';
import 'login_page.dart';

class VerifyAccountPage extends StatefulWidget {
  final String email;
  final String? password;

  const VerifyAccountPage({
    super.key,
    required this.email,
    this.password,
  });

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  static const int _codeLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode =>
      _controllers.map((c) => c.text.trim()).join();

  void _handleVerify() {
    final code = _currentCode;
    if (code.length < _codeLength) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the verification code';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(AuthVerifyRegistrationEmailRequested(
      email: widget.email,
      code: code,
    ));
  }

  void _showSuccessAndProceed({
    required String title,
    required String message,
    required bool popToHome,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
            SizedBox(width: 10),
            Text('Account Verified'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
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
              if (popToHome) {
                final authState = context.read<AuthBloc>().state;
                final needsPhone = authState.currentUser?.phone.trim().isEmpty == true;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => needsPhone
                        ? const CompletePhonePage()
                        : const MainNavigationWrapper(initialIndex: 0),
                  ),
                  (route) => false,
                );
              } else {
                // Navigate to login screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: Text(popToHome ? 'Continue' : 'Sign In Now'),
          ),
        ],
      ),
    );
  }

  void _handleResend() {
    if (!_canResend) return;

    setState(() {
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(AuthResendVerificationRequested(
      email: widget.email,
    ));
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Handle paste of multiple characters
      if (value.length > 1) {
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        for (int i = 0; i < _codeLength && i < digits.length; i++) {
          _controllers[i].text = digits[i];
        }
        final nextIndex = digits.length < _codeLength ? digits.length : _codeLength - 1;
        _focusNodes[nextIndex].requestFocus();
        if (digits.length >= _codeLength) {
          _handleVerify();
        }
        return;
      }

      // Auto advance to next box
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Automatically verify when all 6 digits entered
        if (_currentCode.length == _codeLength) {
          _handleVerify();
        }
      }
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    // If backspace is pressed on empty box, focus previous box
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
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
        if (authState.status == AuthStatus.authenticated) {
          _showSuccessAndProceed(
            title: 'Account Verified!',
            message: 'Your email has been verified successfully. Welcome to our store!',
            popToHome: true,
          );
        } else if (authState.status == AuthStatus.failure && authState.errorMessage != null) {
          setState(() {
            _errorMessage = authState.errorMessage;
          });
        } else if (authState.status == AuthStatus.unauthenticated &&
            authState.successMessage?.toLowerCase().contains('resent') == true) {
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.mark_email_read_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('A new verification code has been sent to your email.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.successGreen,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon Badge
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Verify Your Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle & Email
                  Text(
                    'Please enter the 6-digit verification code sent to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subtextColor, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 6-Digit OTP Input Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (index) {
                      return SizedBox(
                        width: 46,
                        height: 56,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (e) => _onKeyEvent(e, index),
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: surfaceColor,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _controllers[index].text.isNotEmpty
                                      ? AppColors.primary
                                      : borderColor,
                                  width: _controllers[index].text.isNotEmpty ? 1.5 : 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2.0,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.discountRed),
                              ),
                            ),
                            onChanged: (val) => _onDigitChanged(val, index),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Error Message if any
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.discountRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.discountRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.discountRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.discountRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Verify Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleVerify,
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
                            'Verify Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Resend Code Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: TextStyle(color: subtextColor, fontSize: 13),
                      ),
                      if (_canResend)
                        GestureDetector(
                          onTap: isLoading ? null : _handleResend,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Resend in ${_secondsRemaining}s',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(color: borderColor),
                  const SizedBox(height: 16),

                  // Sign in quick link
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
                      label: const Text(
                        'Return to Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
