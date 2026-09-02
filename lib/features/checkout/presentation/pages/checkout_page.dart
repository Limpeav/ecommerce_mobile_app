import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../../features/cart/presentation/bloc/cart_state.dart';
import '../../../../features/orders/presentation/bloc/order_bloc.dart';
import '../../../../features/orders/presentation/bloc/order_event.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/cart_item.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/review_requirement_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../orders/presentation/pages/pending_reviews_page.dart';
import '../widgets/khqr_payment_modal.dart';
import '../widgets/map_location_picker_sheet.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Financial settings fetched from backend (admin-configured)
  FinancialSettings _financialSettings = FinancialSettings.defaults;

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;

  // Selected Pin Location
  SelectedLocation? _selectedLocation;
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isPlacingOrder = false;

  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'title': 'Cash on Delivery',
      'subtitle': 'Pay with cash upon delivery receipt',
      'icon': Icons.local_atm_outlined,
      'badge': 'COD',
      'isKhqr': false,
    },
    {
      'title': 'Bakong KHQR',
      'subtitle': 'Scan to pay with Bakong, ABA or any bank app',
      'icon': Icons.qr_code_2_rounded,
      'badge': 'Bakong KHQR',
      'isKhqr': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Hour Limpeav');
    _streetController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController(text: 'Phnom Penh');
    _phoneController = TextEditingController(text: '16568335');

    // Fetch admin-configured financial settings (shipping, tax, exchange rate)
    _loadFinancialSettings();
  }

  Future<void> _loadFinancialSettings() async {
    final settings = await SettingsService.fetchFinancialSettings();
    if (mounted) {
      setState(() {
        _financialSettings = settings;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthBloc>().state.currentUser;
    if (user != null && user.name.isNotEmpty && _nameController.text == 'Hour Limpeav') {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatKhr(double usdAmount) {
    final khr = (usdAmount * _financialSettings.exchangeRate).round();
    final str = khr.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '៛$buffer';
  }

  Future<void> _openMapLocationPicker() async {
    final result = await MapLocationPickerSheet.show(
      context,
      initialLocation: _selectedLocation,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        if (_streetController.text.isEmpty || _streetController.text.startsWith('Street')) {
          _streetController.text = result.street;
        }
        _cityController.text = result.cityProvince;
        if (_addressController.text.isEmpty) {
          _addressController.text = '${result.district}, ${result.cityProvince}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Selected: ${result.locationName}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePlaceOrder({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double shipping,
    required double tax,
    required double total,
  }) async {
    final pendingReviews = await ReviewRequirementService.getPendingReviewItems();
    if (!mounted) return;
    if (pendingReviews.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PendingReviewsPage(),
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your contact phone number')),
      );
      return;
    }

    if (_selectedLocation == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, size: 36, color: AppColors.accent),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Delivery Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please pin your delivery address on the map so we can deliver your order to the right location.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openMapLocationPicker();
                },
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('📍 Open Map & Pick Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final userToken = context.read<AuthBloc>().state.currentUser?.token;

    if (userToken == null || userToken.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle_outlined, size: 36, color: AppColors.accent),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log In Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in to your account so your order is saved to the database and appears in the admin orders dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Log In / Register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'Bakong KHQR') {
      setState(() {
        _isPlacingOrder = true;
      });

      final deliveryAddress = [
        _nameController.text.trim(),
        _streetController.text.trim(),
        _addressController.text.trim(),
        _cityController.text.trim(),
        '+855 ${_phoneController.text.trim()}',
        if (_selectedLocation != null)
          '(${_selectedLocation!.formattedCoordinates})',
      ].where((part) => part.isNotEmpty).join(', ');

      // 1. Create order on backend first to obtain real MongoDB orderId
      context.read<OrderBloc>().add(
        OrderPlaced(
          items: items,
          subtotal: subtotal,
          discount: discount,
          shipping: shipping,
          tax: tax,
          total: total,
          deliveryAddress: deliveryAddress,
          paymentMethod: _selectedPaymentMethod,
          recipientName: _nameController.text.trim(),
          recipientPhone: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Phnom Penh',
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          authToken: userToken,
          exchangeRate: _financialSettings.exchangeRate,
          onComplete: (order) {
            if (!mounted) return;

            setState(() {
              _isPlacingOrder = false;
            });

            // 2. Show official Bakong KHQR scan modal with created orderId
            KhqrPaymentModal.show(
              context,
              orderId: order.id,
              totalUsd: total,
              totalKhr: total * _financialSettings.exchangeRate,
              orderSummary: 'Cherish Baby Store Order',
              authToken: userToken,
              onPaymentSuccess: () async {
                // Notify backend PUT /api/orders/:id/pay and dispatch Telegram Bot notification
                context.read<OrderBloc>().add(
                  OrderMarkedAsPaid(
                    orderId: order.id,
                    authToken: userToken,
                    exchangeRate: _financialSettings.exchangeRate,
                    paymentResult: {
                      'id': 'BAKONG-${order.id.replaceAll('#', '')}',
                      'status': 'PAID',
                      'method': 'Bakong KHQR',
                    },
                  ),
                );
                context.read<CartBloc>().add(CartCleared(authToken: userToken));
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OrderSuccessPage(
                      order: order.copyWith(isPaid: true, paidAt: DateTime.now()),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    } else {
      _executeOrderPlacement(
        items: items,
        subtotal: subtotal,
        discount: discount,
        shipping: shipping,
        tax: tax,
        total: total,
      );
    }
  }

  Future<void> _executeOrderPlacement({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double shipping,
    required double tax,
    required double total,
  }) async {
    setState(() {
      _isPlacingOrder = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final deliveryAddress = [
      _nameController.text.trim(),
      _streetController.text.trim(),
      _addressController.text.trim(),
      _cityController.text.trim(),
      '+855 ${_phoneController.text.trim()}',
      if (_selectedLocation != null)
        '(${_selectedLocation!.formattedCoordinates})',
    ].where((part) => part.isNotEmpty).join(', ');

    final userToken = context.read<AuthBloc>().state.currentUser?.token;

    context.read<OrderBloc>().add(
      OrderPlaced(
        items: items,
        subtotal: subtotal,
        discount: discount,
        shipping: shipping,
        tax: tax,
        total: total,
        deliveryAddress: deliveryAddress,
        paymentMethod: _selectedPaymentMethod,
        recipientName: _nameController.text.trim(),
        recipientPhone: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Phnom Penh',
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        authToken: userToken,
        exchangeRate: _financialSettings.exchangeRate,
        onComplete: (order) {
          context.read<CartBloc>().add(const CartCleared());
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(order: order),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        // Use cart items or default sample item if empty
        final List<CartItem> displayItems = cartState.items.isNotEmpty
            ? cartState.items
            : [
                CartItem(
                  product: const Product(
                    id: 'prod_bloomcare_teething',
                    title: 'BloomCare Silicone Teething Set',
                    category: 'Feeding & Teething',
                    price: 24.99,
                    originalPrice: 29.99,
                    rating: 4.9,
                    ratingCount: 142,
                    image:
                        'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
                    images: [
                      'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?auto=format&fit=crop&w=400&q=80',
                    ],
                    description: 'BPA-free food grade silicone teether set.',
                    stock: 25,
                    availableColors: ['Sage Green', 'Warm Peach'],
                    availableSizes: ['Standard'],
                    reviews: [],
                  ),
                  quantity: 1,
                  selectedColor: 'Sage Green',
                  selectedSize: 'Standard',
                ),
              ];

        final double itemsSubtotal = cartState.items.isNotEmpty
            ? cartState.subtotal
            : displayItems.fold(0.0, (sum, i) => sum + i.totalPrice);

        final double discount = cartState.items.isNotEmpty ? cartState.discountAmount : 0.0;
        final double shipping = _financialSettings.effectiveShipping(itemsSubtotal - discount);
        final double tax = (itemsSubtotal - discount) * _financialSettings.taxRate;
        final double total = (itemsSubtotal - discount) + shipping + tax;

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFCF9F5),
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.child_care_rounded, color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cherish Baby Store',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= 1. SHIPPING ADDRESS CARD =================
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.location_on_outlined,
                  title: 'Shipping Address',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FULL NAME
                      _buildFieldLabel('FULL NAME'),
                      const SizedBox(height: 6),
                      _buildInputPill(
                        isDark: isDark,
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        hintText: 'Enter your full name',
                      ),
                      const SizedBox(height: 16),

                      // PIN LOCATION
                      _buildFieldLabel('PIN LOCATION'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _openMapLocationPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D312E) : const Color(0xFFF4EFEB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedLocation != null
                                  ? AppColors.accent
                                  : (isDark ? AppColors.borderDark : const Color(0xFFEAE3DB)),
                              width: _selectedLocation != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedLocation != null
                                          ? _selectedLocation!.locationName
                                          : 'Select Location on Map',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedLocation != null
                                            ? AppColors.accent
                                            : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                    if (_selectedLocation != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedLocation!.formattedCoordinates,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      if (_selectedLocation!.noteForDriver.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Note: ${_selectedLocation!.noteForDriver}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.accent.withAlpha(80)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedLocation != null ? Icons.edit_location_alt : Icons.map_outlined,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedLocation != null ? 'Change' : 'Open Map',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // STREET (Optional)
                      _buildFieldLabel('STREET (Optional)'),
                      const SizedBox(height: 6),
                      _buildInputPill(
                        isDark: isDark,
                        prefixIcon: Icons.apartment_outlined,
                        controller: _streetController,
                        hintText: 'Enter street name or number',
                      ),
                      const SizedBox(height: 16),

                      // ADDRESS (Optional)
                      _buildFieldLabel('ADDRESS (Optional)'),
                      const SizedBox(height: 6),
                      _buildInputPill(
                        isDark: isDark,
                        prefixIcon: Icons.home_work_outlined,
                        controller: _addressController,
                        hintText: 'Enter address details',
                      ),
                      const SizedBox(height: 16),

                      // CITY / PROVINCE & PHONE NUMBER (Responsive Row / Columns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // City / Province
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('CITY / PROVINCE (Optional)'),
                                const SizedBox(height: 6),
                                _buildInputPill(
                                  isDark: isDark,
                                  controller: _cityController,
                                  hintText: 'Enter city or province',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Phone Number with +855 prefix pill
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('PHONE NUMBER'),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2D312E) : const Color(0xFFF4EFEB),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : const Color(0xFFEAE3DB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '+855',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            hintText: '16568335',
                                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= 2. PAYMENT METHOD CARD =================
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment Method',
                  child: Column(
                    children: _paymentOptions.map((opt) {
                      final isSelected = _selectedPaymentMethod == opt['title'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPaymentMethod = opt['title'] as String;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF2B3A2E) : const Color(0xFFF2F7F3))
                                : (isDark ? const Color(0xFF2D312E) : const Color(0xFFF4EFEB)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : (isDark ? AppColors.borderDark : const Color(0xFFEAE3DB)),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accent : Colors.grey.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  opt['icon'] as IconData,
                                  color: isSelected ? Colors.white : Colors.grey,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          opt['title'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected ? AppColors.accent : null,
                                          ),
                                        ),
                                        if (opt['badge'] != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: opt['badge'] == 'Bakong KHQR'
                                                  ? const Color(0xFFDC2626).withAlpha(30)
                                                  : AppColors.accentLight,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              opt['badge'] as String,
                                              style: TextStyle(
                                                color: opt['badge'] == 'Bakong KHQR'
                                                    ? const Color(0xFFDC2626)
                                                    : AppColors.accent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt['subtitle'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildRadioIndicator(isSelected),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // ================= 3. ORDER SUMMARY CARD =================
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.inventory_2_outlined,
                  title: 'Order Summary',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items Preview List
                      ...displayItems.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D312E) : const Color(0xFFF4EFEB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item.product.image,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 54,
                                    height: 54,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'QTY: ${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '(${_formatKhr(item.totalPrice)})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      // Financial Breakdown
                      _buildSummaryLine(
                        'Subtotal',
                        '\$${itemsSubtotal.toStringAsFixed(2)}',
                        _formatKhr(itemsSubtotal),
                        isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryLine(
                        'Shipping',
                        '\$${shipping.toStringAsFixed(2)}',
                        _formatKhr(shipping),
                        isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryLine(
                        'Tax (8%)',
                        '\$${tax.toStringAsFixed(2)}',
                        _formatKhr(tax),
                        isDark,
                      ),
                      const SizedBox(height: 12),

                      // Exchange Rate Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282C29) : const Color(0xFFF0EBE4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Exchange Rate',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                              ),
                            ),
                            const Text(
                              '1 USD = 4,100 KHR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                '(${_formatKhr(total)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Place Order CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder
                              ? null
                              : () => _handlePlaceOrder(
                                    items: displayItems,
                                    subtotal: itemsSubtotal,
                                    discount: discount,
                                    shipping: shipping,
                                    tax: tax,
                                    total: total,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B8E7B), // Cherish Sage Green
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isPlacingOrder
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Placing Order...',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Place Order',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secure Payment Badge
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Secure Payment',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEAE3DB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D3830) : const Color(0xFFEBF1EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Color(0xFF8A8F8A),
      ),
    );
  }

  Widget _buildInputPill({
    required bool isDark,
    IconData? prefixIcon,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D312E) : const Color(0xFFF4EFEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEAE3DB),
        ),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.accent : Colors.grey,
          width: isSelected ? 6 : 1.5,
        ),
        color: isSelected ? AppColors.accent : Colors.transparent,
      ),
    );
  }

  Widget _buildSummaryLine(String label, String usd, String khr, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          ),
        ),
        Row(
          children: [
            Text(
              usd,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($khr)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
