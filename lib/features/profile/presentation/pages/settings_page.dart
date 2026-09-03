import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/bloc/theme_cubit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/forgot_password_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'change_password_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState.currentUser;
          final isAuthenticated = authState.isAuthenticated;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Account & Security
              _buildSectionHeader('Account & Security', textColor),
              const SizedBox(height: 8),
              _buildCardGroup(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                children: [
                  if (isAuthenticated && user != null) ...[
                    _buildMenuTile(
                      icon: CupertinoIcons.person_crop_circle_fill,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFFF0FDFA),
                      title: 'Personal Information',
                      subtitle: '${user.name.isNotEmpty ? user.name : 'Update profile'} • ${user.email}',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () => _showEditProfileDialog(context, user),
                    ),
                    _buildDivider(borderColor),
                    _buildMenuTile(
                      icon: CupertinoIcons.lock_shield_fill,
                      iconColor: const Color(0xFF6366F1),
                      iconBg: const Color(0xFFEEF2FF),
                      title: 'Change Password',
                      subtitle: 'Update your account login password',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangePasswordPage(userEmail: user.email),
                        ),
                      ),
                    ),
                    _buildDivider(borderColor),
                  ] else ...[
                    _buildMenuTile(
                      icon: CupertinoIcons.person_badge_plus_fill,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primary.withValues(alpha: 0.12),
                      title: 'Sign In / Register',
                      subtitle: 'Log in to manage orders, addresses & security',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    _buildDivider(borderColor),
                  ],
                  _buildMenuTile(
                    icon: CupertinoIcons.question_circle_fill,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                    title: 'Forgot Password',
                    subtitle: 'Reset password via email verification code',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordPage(
                          initialEmail: user?.email,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Appearance & Preferences
              _buildSectionHeader('Preferences', textColor),
              const SizedBox(height: 8),
              _buildCardGroup(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildTileIcon(
                      CupertinoIcons.moon_fill,
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.12),
                    ),
                    title: Text(
                      'Dark Appearance',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                    ),
                    subtitle: Text(
                      isDark ? 'Dark theme enabled' : 'Light cream theme enabled',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                    ),
                  ),
                  _buildDivider(borderColor),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: _buildTileIcon(
                      CupertinoIcons.bell_fill,
                      const Color(0xFF0284C7),
                      const Color(0xFFF0F9FF),
                    ),
                    title: Text(
                      'Order & Deal Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                    ),
                    subtitle: Text(
                      _notificationsEnabled ? 'Instant updates enabled' : 'Muted',
                      style: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _notificationsEnabled ? 'Notifications enabled' : 'Notifications disabled',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: CupertinoIcons.globe,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'Language & Currency',
                    subtitle: 'English (US) • USD (\$) & KHR (៛)',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    onTap: () => _showLanguageModal(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Support & Policies
              _buildSectionHeader('Support & Legal', textColor),
              const SizedBox(height: 8),
              _buildCardGroup(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                children: [
                  _buildMenuTile(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primary.withValues(alpha: 0.12),
                    title: '24/7 Customer Care & Live Chat',
                    subtitle: 'Phone, email & Telegram customer support',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    onTap: () => _showSupportModal(context, isDark),
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: CupertinoIcons.paperplane_fill,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                    title: 'Shipping & Delivery FAQs',
                    subtitle: 'Phnom Penh same-day & nationwide 1-2 days',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    onTap: () => _showShippingInfoModal(context, isDark),
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: CupertinoIcons.arrow_2_squarepath,
                    iconColor: const Color(0xFFEC4899),
                    iconBg: const Color(0xFFFDF2F8),
                    title: '7-Day Return & Guarantee Policy',
                    subtitle: '100% genuine baby essentials guarantee',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    onTap: () => _showReturnPolicyModal(context, isDark),
                  ),
                  _buildDivider(borderColor),
                  _buildMenuTile(
                    icon: CupertinoIcons.shield_fill,
                    iconColor: const Color(0xFF64748B),
                    iconBg: const Color(0xFFF8FAFC),
                    title: 'Privacy & Terms of Service',
                    subtitle: 'Customer privacy and data security',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    onTap: () => _showPrivacyModal(context, isDark),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Sign Out Button (if authenticated)
              if (isAuthenticated) ...[
                OutlinedButton.icon(
                  onPressed: () => _showSignOutConfirmDialog(context),
                  icon: const Icon(CupertinoIcons.square_arrow_right, color: AppColors.discountRed, size: 18),
                  label: const Text(
                    'Sign Out of Account',
                    style: TextStyle(
                      color: AppColors.discountRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.discountRed, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Footer
              Center(
                child: Text(
                  'Cherish Baby Store • Version 2.4.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtextColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor.withValues(alpha: 0.6),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildTileIcon(icon, iconColor, iconBg),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subtextColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(CupertinoIcons.chevron_forward, size: 16, color: subtextColor),
      onTap: onTap,
    );
  }

  Widget _buildTileIcon(IconData icon, Color color, Color bg) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(height: 1, thickness: 1, color: borderColor, indent: 64);
  }

  void _showEditProfileDialog(BuildContext context, UserEntity user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Edit Profile Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Ensure your name and phone are accurate.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(CupertinoIcons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(CupertinoIcons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Phone number is required';
                      if (val.replaceAll(RegExp(r'\D'), '').length < 8) return 'Please enter at least 8 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.of(ctx).pop();
                      context.read<AuthBloc>().add(AuthUpdateProfileRequested(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                          ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSignOutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your Cherish Baby Store account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.discountRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.of(context).pop();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Language & Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English (United States)', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(CupertinoIcons.checkmark_alt, color: AppColors.primary),
              onTap: () => Navigator.of(ctx).pop(),
            ),
            ListTile(
              leading: const Text('🇰🇭', style: TextStyle(fontSize: 24)),
              title: const Text('ភាសាខ្មែរ (Khmer - Coming Soon)', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('24/7 Priority Customer Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Reach our customer service team anytime:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            const ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.accentLight, child: Icon(CupertinoIcons.phone_fill, color: AppColors.primary)),
              title: Text('+855 23 888 123', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Call Center (8:00 AM - 9:00 PM)'),
            ),
            const ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.accentLight, child: Icon(CupertinoIcons.mail_solid, color: AppColors.primary)),
              title: Text('support@cherishbabystore.com', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Email Response within 24h'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShippingInfoModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Shipping & Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('• Phnom Penh: Same-day express delivery for orders before 2:00 PM.\n• Nationwide Provinces: 1-2 business days with insured courier.\n• Free Delivery on orders over \$50.', style: TextStyle(height: 1.5, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got It'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnPolicyModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('7-Day Return & Guarantee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('• Free exchange or full refund within 7 days for unopened baby essentials.\n• 100% genuine baby essentials guarantee.\n• Easy pickup from your door.', style: TextStyle(height: 1.5, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Privacy Policy & Terms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Your personal information, delivery addresses, and payment data are encrypted with bank-level security and are never sold to third parties.', style: TextStyle(height: 1.5, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
