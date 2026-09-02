import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/main_navigation_wrapper.dart';
import '../pages/complete_phone_page.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onSuccess;
  final String text;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : const Color(0xFF3C4043);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFDADCE0);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && state.currentUser != null) {
          final user = state.currentUser!;
          final displayName = user.name.isNotEmpty == true ? user.name : 'Google Account';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Signed in as $displayName'),
                  ),
                ],
              ),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );

          final hasPhone = user.phone.trim().isNotEmpty;

          if (!hasPhone) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const CompletePhonePage(),
              ),
              (route) => false,
            );
          } else if (onSuccess != null) {
            onSuccess!();
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainNavigationWrapper(initialIndex: 0),
              ),
              (route) => false,
            );
          }
        } else if (state.status == AuthStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: AppColors.discountRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: surfaceColor,
              foregroundColor: textColor,
              side: BorderSide(color: borderColor, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: isLoading
                ? null
                : () {
                    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
                  },
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google "G" Badge
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: const Size(22, 22),
                          painter: _GoogleLogoPainter(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Blue Bar
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(center.dx, center.dy - 2.5)
      ..lineTo(w, center.dy - 2.5)
      ..lineTo(w, center.dy + 2.5)
      ..lineTo(center.dx, center.dy + 2.5)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Outer ring segments
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.butt;

    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -0.78,
      1.57,
      false,
      strokePaint,
    );

    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      0.79,
      1.57,
      false,
      strokePaint,
    );

    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      2.36,
      1.57,
      false,
      strokePaint,
    );

    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      3.93,
      1.57,
      false,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
