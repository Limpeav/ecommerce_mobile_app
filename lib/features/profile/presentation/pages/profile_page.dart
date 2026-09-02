import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/profile/presentation/bloc/address_cubit.dart';
import '../../../../features/profile/presentation/bloc/address_state.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_state.dart';
import '../../../../features/notifications/presentation/bloc/notification_cubit.dart';
import '../../../../features/notifications/presentation/bloc/notification_state.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_event.dart';
import '../../../../features/orders/presentation/bloc/order_state.dart';
import '../../../../core/theme/bloc/theme_cubit.dart';
import '../../../../core/theme/bloc/locale_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../../../features/wishlist/presentation/bloc/wishlist_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/order.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../notifications/presentation/pages/notification_center_page.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import '../../../orders/presentation/pages/pending_reviews_page.dart';
import '../../../store_locator/presentation/pages/store_locator_page.dart';
import 'address_book_page.dart';

class ProfilePage extends StatefulWidget {
  final Function(int) onTabChange;

  const ProfilePage({super.key, required this.onTabChange});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders() async {
    final token = context.read<AuthBloc>().state.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      context.read<OrderBloc>().add(OrderFetchRequested(authToken: token));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Account & Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, notifState) {
              final unread = notifState.unreadCount;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationCenterPage(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(CupertinoIcons.bell, size: 21),
                    if (unread > 0)
                      Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33E53935),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon_fill,
              color: isDark ? AppColors.warmAmber : AppColors.primary,
              size: 22,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.headphones, size: 22),
            tooltip: 'Support & Help',
            onPressed: () => _showSupportModal(context, isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchOrders,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.currentUser;
            final isAuthenticated = authState.isAuthenticated;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Profile Header Card (User / Guest)
                  if (isAuthenticated && user != null)
                    _buildUserHeaderCard(context, user, isDark, cardColor, textColor, subtextColor, borderColor)
                  else
                    _buildGuestHeaderCard(context, isDark, cardColor, textColor, subtextColor, borderColor),

                  const SizedBox(height: 16),

                  // 2. Quick Overview Counter Bar
                  _buildQuickStatsBar(context, isDark, cardColor, textColor, subtextColor, borderColor),

                  const SizedBox(height: 16),

                  // 3. My Orders Status Dashboard
                  _buildOrdersDashboard(context, isDark, cardColor, textColor, subtextColor, borderColor),

                  const SizedBox(height: 16),

                  // 4. VIP Rewards Club Banner
                  _buildRewardsBanner(context, isDark, isAuthenticated),

                  const SizedBox(height: 16),

                  // 5. Shopping & Orders Group
                  _buildSectionHeader('Shopping & Services', textColor),
                  const SizedBox(height: 8),
                  _buildCardGroup(
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    children: [
                      _buildMenuTile(
                        icon: CupertinoIcons.doc_plaintext,
                        iconColor: const Color(0xFF4F46E5),
                        iconBg: const Color(0xFFEEF2FF),
                        title: 'All Orders & Invoices',
                        subtitle: 'Track live status, delivery & reorder items',
                        isDark: isDark,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrdersPage()),
                        ),
                      ),
                      _buildDivider(borderColor),
                      BlocBuilder<OrderBloc, OrderState>(
                        builder: (context, orderState) {
                          final pendingCount = orderState.pendingReviewItems.length;
                          return _buildMenuTile(
                            icon: CupertinoIcons.star_circle_fill,
                            iconColor: const Color(0xFFEAB308),
                            iconBg: const Color(0xFFFEFCE8),
                            title: 'Product Reviews & Ratings',
                            subtitle: pendingCount > 0
                                ? '$pendingCount delivered item${pendingCount == 1 ? '' : 's'} waiting for review'
                                : 'Rate your delivered purchases',
                            isDark: isDark,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            trailingBadge: pendingCount > 0 ? '$pendingCount Required' : null,
                            badgeColor: AppColors.discountRed,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PendingReviewsPage()),
                            ),
                          );
                        },
                      ),
                      _buildDivider(borderColor),
                      BlocBuilder<AddressCubit, AddressState>(
                        builder: (context, addressState) {
                          final count = addressState.addresses.length;
                          return _buildMenuTile(
                            icon: CupertinoIcons.location_solid,
                            iconColor: const Color(0xFFEA580C),
                            iconBg: const Color(0xFFFFF7ED),
                            title: 'Delivery Addresses',
                            subtitle: '$count saved address${count == 1 ? '' : 'es'} for fast checkout',
                            isDark: isDark,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            trailingBadge: count > 0 ? '$count' : null,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddressBookPage()),
                            ),
                          );
                        },
                      ),
                      _buildDivider(borderColor),
                      _buildMenuTile(
                        icon: CupertinoIcons.building_2_fill,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFECFDF5),
                        title: 'Store Outlets & Pickup Points',
                        subtitle: 'Find physical stores, opening hours & contact',
                        isDark: isDark,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StoreLocatorPage()),
                        ),
                      ),
                      _buildDivider(borderColor),
                      _buildMenuTile(
                        icon: CupertinoIcons.ticket_fill,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFEF3C7),
                        title: 'Vouchers & Promo Codes',
                        subtitle: 'Save extra on diapers, toys & baby essentials',
                        isDark: isDark,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        trailingBadge: '2 Active',
                        badgeColor: AppColors.warmAmber,
                        onTap: () => _showPromoCodesModal(context, isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 6. Preferences & Settings Group
                  _buildSectionHeader('Preferences & Security', textColor),
                  const SizedBox(height: 8),
                  _buildCardGroup(
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    children: [
                      // Dark Mode Switch
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
                      // Notifications Switch
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
                                content: Text(_notificationsEnabled ? 'Notifications enabled' : 'Notifications disabled'),
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
                        isDark: isDark,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _showLanguageModal(context, isDark),
                      ),
                      if (isAuthenticated && user != null) ...[
                        _buildDivider(borderColor),
                        _buildMenuTile(
                          icon: CupertinoIcons.person_crop_circle,
                          iconColor: const Color(0xFF0D9488),
                          iconBg: const Color(0xFFF0FDFA),
                          title: 'Personal Information',
                          subtitle: 'Update your name, contact phone & avatar',
                          isDark: isDark,
                          textColor: textColor,
                          subtextColor: subtextColor,
                          onTap: () => _showEditProfileDialog(context, user),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 7. Customer Care & Legal
                  _buildSectionHeader('Support & Information', textColor),
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
                        subtitle: 'Direct phone, email & telegram assistance',
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        subtitle: 'Secure customer data and payment protection',
                        isDark: isDark,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => _showPrivacyModal(context, isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 8. Sign Out / Login CTA Button
                  if (isAuthenticated)
                    _buildSignOutButton(context, isDark)
                  else
                    _buildLoginBannerButton(context),

                  const SizedBox(height: 20),

                  // 9. App Branding Footer
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'Assets/splash_screen/app_icon.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cherish Baby Store',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor.withValues(alpha: 0.8),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 2.4.0 • Crafted with care for parents & babies',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtextColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== 1. USER HEADER CARD ====================
  Widget _buildUserHeaderCard(
    BuildContext context,
    UserEntity user,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    String displayName = user.name.trim();
    if (displayName.isEmpty ||
        displayName.toLowerCase() == 'customer' ||
        displayName.toLowerCase() == 'google user') {
      if (user.email.isNotEmpty) {
        displayName = user.email.split('@').first;
      } else {
        displayName = 'Valued Customer';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Edit Badge
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                      child: user.avatarUrl.isEmpty
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfileDialog(context, user),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // User Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 17,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(CupertinoIcons.mail, size: 13, color: subtextColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.email,
                            style: TextStyle(fontSize: 12, color: subtextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(CupertinoIcons.phone, size: 13, color: subtextColor),
                          const SizedBox(width: 4),
                          Text(
                            user.phone,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Membership Level Pill & Edit Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.accentLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.star_circle_fill, size: 18, color: AppColors.warmAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cherish Gold Member • Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.warmAmber : AppColors.primaryDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditProfileDialog(context, user),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 1. GUEST HEADER CARD ====================
  Widget _buildGuestHeaderCard(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.person_fill, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Cherish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sign in for real-time order tracking, address book & loyalty points.',
                      style: TextStyle(fontSize: 12, color: subtextColor, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 2. QUICK STATS BAR ====================
  Widget _buildQuickStatsBar(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, orderState) {
        return BlocBuilder<WishlistBloc, WishlistState>(
          builder: (context, wishlistState) {
            return BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                return BlocBuilder<AddressCubit, AddressState>(
                  builder: (context, addressState) {
                    final totalOrders = orderState.orders.length;
                    final totalWishlist = wishlistState.count;
                    final totalCart = cartState.itemCount;
                    final totalAddress = addressState.addresses.length;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            count: '$totalOrders',
                            label: 'Orders',
                            icon: CupertinoIcons.doc_text_fill,
                            color: const Color(0xFF4F46E5),
                            textColor: textColor,
                            subtextColor: subtextColor,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OrdersPage()),
                            ),
                          ),
                          _buildVerticalDivider(borderColor),
                          _buildStatItem(
                            count: '$totalWishlist',
                            label: 'Wishlist',
                            icon: CupertinoIcons.heart_fill,
                            color: AppColors.discountRed,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            onTap: () => widget.onTabChange(3),
                          ),
                          _buildVerticalDivider(borderColor),
                          _buildStatItem(
                            count: '$totalCart',
                            label: 'In Bag',
                            icon: CupertinoIcons.bag_fill,
                            color: AppColors.primary,
                            textColor: textColor,
                            subtextColor: subtextColor,
                            onTap: () => widget.onTabChange(2),
                          ),
                          _buildVerticalDivider(borderColor),
                          _buildStatItem(
                            count: '$totalAddress',
                            label: 'Addresses',
                            icon: CupertinoIcons.location_fill,
                            color: const Color(0xFFEA580C),
                            textColor: textColor,
                            subtextColor: subtextColor,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddressBookPage()),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 28,
      color: borderColor,
    );
  }

  // ==================== 3. ORDERS DASHBOARD ====================
  Widget _buildOrdersDashboard(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, orderState) {
        final orders = orderState.orders;

        int toPayCount = 0;
        int processingCount = 0;
        int shippedCount = 0;
        int deliveredCount = 0;

        for (final o in orders) {
          switch (o.status) {
            case OrderStatus.placed:
              toPayCount++;
              break;
            case OrderStatus.processing:
              processingCount++;
              break;
            case OrderStatus.shipped:
            case OrderStatus.outForDelivery:
              shippedCount++;
              break;
            case OrderStatus.delivered:
              deliveredCount++;
              break;
            case OrderStatus.cancelled:
              break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.cube_box_fill, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'My Orders',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_forward, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOrderStatusTile(
                    label: 'To Pay',
                    icon: CupertinoIcons.creditcard,
                    badgeCount: toPayCount,
                    isDark: isDark,
                    textColor: textColor,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
                    ),
                  ),
                  _buildOrderStatusTile(
                    label: 'Processing',
                    icon: CupertinoIcons.cube_box,
                    badgeCount: processingCount,
                    isDark: isDark,
                    textColor: textColor,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
                    ),
                  ),
                  _buildOrderStatusTile(
                    label: 'Shipped',
                    icon: CupertinoIcons.car_detailed,
                    badgeCount: shippedCount,
                    isDark: isDark,
                    textColor: textColor,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
                    ),
                  ),
                  _buildOrderStatusTile(
                    label: 'Delivered',
                    icon: CupertinoIcons.checkmark_circle,
                    badgeCount: deliveredCount,
                    isDark: isDark,
                    textColor: textColor,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusTile({
    required String label,
    required IconData icon,
    required int badgeCount,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceSoftDark : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.discountRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 4. REWARDS BANNER ====================
  Widget _buildRewardsBanner(BuildContext context, bool isDark, bool isAuthenticated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF2E332F), Color(0xFF1E211F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF7A967E), Color(0xFF536E57)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.star_fill, color: Color(0xFFFFD54F), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cherish Rewards Club',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAuthenticated
                      ? 'You have 240 Loyalty Points (\$2.40 value)'
                      : 'Earn points on every order & unlock special discounts',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_forward, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  // ==================== SECTION HELPERS ====================
  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
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
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
    String? trailingBadge,
    Color? badgeColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildTileIcon(icon, iconColor, isDark ? iconColor.withValues(alpha: 0.15) : iconBg),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtextColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailingBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? AppColors.primary,
                ),
              ),
            ),
          const Icon(CupertinoIcons.chevron_forward, size: 16, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildTileIcon(IconData icon, Color color, Color bg) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: borderColor,
    );
  }

  // ==================== BUTTONS ====================
  Widget _buildSignOutButton(BuildContext context, bool isDark) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.discountRed,
        side: BorderSide(color: AppColors.discountRed.withValues(alpha: 0.4), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => _showSignOutDialog(context),
      icon: const Icon(CupertinoIcons.square_arrow_right, size: 18),
      label: const Text(
        'Sign Out of Account',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  Widget _buildLoginBannerButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      ),
      icon: const Icon(CupertinoIcons.person_crop_circle_badge_plus, size: 18),
      label: const Text(
        'Sign In to Cherish Account',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  // ==================== DIALOGS & MODALS ====================
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account on this device?'),
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserEntity? user) {
    if (user == null) return;
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                  const Text(
                    'Edit Profile Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ensure your name and phone are accurate for seamless delivery.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                      labelText: 'Phone Number (Required)',
                      prefixIcon: Icon(CupertinoIcons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Phone number is required';
                      if (val.replaceAll(RegExp(r'\D'), '').length < 8) {
                        return 'Please enter at least 8 digits';
                      }
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
            const Text(
              '24/7 Priority Customer Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our team is always ready to assist with orders, returns, and baby product advice.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.accentLight,
                child: Icon(CupertinoIcons.phone_fill, color: AppColors.primary),
              ),
              title: const Text('+855 23 888 123', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Call Center (8:00 AM - 9:00 PM)'),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '+855 23 888 123'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number copied to clipboard!')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.accentLight,
                child: Icon(CupertinoIcons.mail_solid, color: AppColors.primary),
              ),
              title: const Text('support@cherishbabystore.com', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Email inquiries (24h response)'),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'support@cherishbabystore.com'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support email copied to clipboard!')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(CupertinoIcons.paperplane_fill, color: Color(0xFF0284C7)),
              ),
              title: const Text('@CherishBabySupport', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Official Telegram Live Chat'),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '@CherishBabySupport'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Telegram handle copied!')),
                );
              },
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

  void _showPromoCodesModal(BuildContext context, bool isDark) {
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
            const Text(
              'Active Promo Coupons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.tag_fill, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WELCOME10', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('10% OFF on your first purchase over \$20', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'WELCOME10'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promo code WELCOME10 copied!')),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warmAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.car_detailed, color: AppColors.warmAmber, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FREESHIP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('Free shipping on all orders over \$35', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'FREESHIP'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Promo code FREESHIP copied!')),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return BlocBuilder<LocaleCubit, Locale>(
          builder: (dialogCtx, activeLocale) {
            final isKhmer = activeLocale.languageCode == 'km';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.languageAndCurrency ?? 'Language & Currency',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.selectLanguage ?? 'Select Language',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  _buildLanguageOption(
                    flag: '🇺🇸',
                    label: 'English',
                    isSelected: !isKhmer,
                    isDark: isDark,
                    onTap: () {
                      context.read<LocaleCubit>().changeLocale(const Locale('en'));
                    },
                  ),
                  _buildLanguageOption(
                    flag: '🇰🇭',
                    label: 'ភាសាខ្មែរ (Khmer)',
                    isSelected: isKhmer,
                    isDark: isDark,
                    onTap: () {
                      context.read<LocaleCubit>().changeLocale(const Locale('km'));
                    },
                  ),
                  const Divider(height: 24),
                  Text(
                    isKhmer ? 'រូបិយប័ណ្ណ' : 'Currencies Supported',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text('• USD (\$): Primary payment'),
                  const SizedBox(height: 4),
                  const Text('• KHR (៛): Cambodian Riel (4,100 ៛ / \$ via KHQR)'),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n?.close ?? 'Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : (isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showShippingInfoModal(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shipping & Delivery'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🛵 Phnom Penh Express Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Delivery within 2 - 4 hours or same-day schedule.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 12),
            Text('🚚 Nationwide Provinces', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Express bus / parcel delivery within 1 - 2 business days.', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showReturnPolicyModal(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('7-Day Guarantee Policy'),
        content: const Text(
          'All items sold at Cherish Baby Store are 100% authentic. We accept returns or exchanges within 7 days of delivery for defective or unopened products in original packaging.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyModal(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Cherish Baby Store respects your privacy. Your personal information, delivery addresses, and payment details are encrypted and securely stored. We never sell your data.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
