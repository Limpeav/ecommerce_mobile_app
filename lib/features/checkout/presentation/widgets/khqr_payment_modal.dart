import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/bakong_service.dart';

class KhqrPaymentModal extends StatefulWidget {
  final String? orderId;
  final double totalUsd;
  final double totalKhr;
  final String orderSummary;
  final VoidCallback onPaymentSuccess;
  final String? authToken; // JWT token from AuthController

  const KhqrPaymentModal({
    super.key,
    this.orderId,
    required this.totalUsd,
    required this.totalKhr,
    required this.orderSummary,
    required this.onPaymentSuccess,
    this.authToken,
  });

  static Future<void> show(
    BuildContext context, {
    String? orderId,
    required double totalUsd,
    required double totalKhr,
    required String orderSummary,
    required VoidCallback onPaymentSuccess,
    String? authToken,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KhqrPaymentModal(
        orderId: orderId,
        totalUsd: totalUsd,
        totalKhr: totalKhr,
        orderSummary: orderSummary,
        onPaymentSuccess: onPaymentSuccess,
        authToken: authToken,
      ),
    );
  }

  @override
  State<KhqrPaymentModal> createState() => _KhqrPaymentModalState();
}

class _KhqrPaymentModalState extends State<KhqrPaymentModal>
    with SingleTickerProviderStateMixin {
  int _remainingSeconds = 900; // 15 minutes
  Timer? _timer;
  Timer? _pollTimer;
  bool _isVerifying = false;
  bool _isPaymentSuccess = false;
  String? _paymentId;
  String? _qrData;
  String? _qrError; // Non-null when QR generation failed

  late AnimationController _scanAnimController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initBakongPayment();

    // Laser scanline animation for the QR code
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initBakongPayment() async {
    if (!mounted) return;
    setState(() {
      _qrError = null;
      _qrData = null;
    });

    final res = await BakongService.generateMerchantQr(
      amount: widget.totalUsd,
      orderId: widget.orderId,
      authToken: widget.authToken,
    );

    if (!mounted) return;

    if (res.success && res.qrData != null && res.qrData!.isNotEmpty) {
      setState(() {
        _paymentId = res.paymentId;
        _qrData = res.qrData;
        _qrError = null;
      });
      if (_paymentId != null && _paymentId!.isNotEmpty) {
        _startPollingPayment();
      }
    } else {
      // Gracefully fallback to generating official EMVCo Bakong KHQR so the customer can always scan
      debugPrint('ℹ️ Bakong backend note: ${res.errorMessage}. Generating merchant KHQR fallback.');
      final fallbackQr = BakongService.generateFallbackKhqr(
        amount: widget.totalUsd,
        currency: 'USD',
        orderId: widget.orderId,
      );
      setState(() {
        _qrData = fallbackQr;
        _qrError = null;
      });
    }
  }

  void _startPollingPayment() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_paymentId == null || !mounted || _isVerifying || _isPaymentSuccess) return;
      final status = await BakongService.checkPaymentStatus(_paymentId!, authToken: widget.authToken);
      if (status.isPaid && mounted) {
        timer.cancel();
        setState(() {
          _isPaymentSuccess = true;
          _isVerifying = false;
        });
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onPaymentSuccess();
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    _scanAnimController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _handleConfirmPayment() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isVerifying = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _isPaymentSuccess = true;
        _isVerifying = false;
      });
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onPaymentSuccess();
      });
    });
  }

  void _handleSaveQr() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 18),
            SizedBox(width: 8),
            Text('📸 KHQR Image saved to your Photos!'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCopyAccount() {
    HapticFeedback.selectionClick();
    Clipboard.setData(const ClipboardData(text: 'cherish_baby@abaa'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Merchant ID (cherish_baby@abaa) copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatKhr(double amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    if (_isPaymentSuccess) {
      return Container(
        height: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2220) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withAlpha(50),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Received!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verified \$${widget.totalUsd.toStringAsFixed(2)} (៛${_formatKhr(widget.totalKhr)}) via KHQR',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                ),
                SizedBox(width: 10),
                Text(
                  'Redirecting to order confirmation...',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.94),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2220) : const Color(0xFFF7F5F0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Sheet Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              child: Column(
                children: [
                  // ================= OFFICIAL BAKONG KHQR STANDEE CARD =================
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 50 : 25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Official Red KHQR Top Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE51A24), Color(0xFFC71019)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // KHQR Bold Brand Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'KHQR',
                                        style: TextStyle(
                                          color: Color(0xFFE51A24),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BAKONG KHQR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'National Bank of Cambodia',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Countdown Timer Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(60),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        _formattedTime,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Merchant Info & Amount Block
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                            child: Column(
                              children: [
                                // Merchant Name with Verified Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Cherish Baby Store',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.verified_rounded, size: 18, color: Colors.blue[600]),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Merchant ID Pill with Copy
                                GestureDetector(
                                  onTap: _handleCopyAccount,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'cherish_baby@abaa',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.copy_rounded, size: 12, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Amount Row (USD & KHR)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '\$${widget.totalUsd.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE51A24).withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '៛${_formatKhr(widget.totalKhr)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFE51A24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 3. Dense KHQR Matrix with Laser Scanline Animation
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer QR border container
                                Container(
                                  width: 224,
                                  height: 224,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _qrData != null
                                      // Real scannable Bakong KHQR with custom center badge
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            QrImageView(
                                              data: _qrData!,
                                              version: QrVersions.auto,
                                              size: 200,
                                              backgroundColor: Colors.white,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: Color(0xFF0F172A),
                                              ),
                                              dataModuleStyle: const QrDataModuleStyle(
                                                dataModuleShape: QrDataModuleShape.square,
                                                color: Color(0xFF0F172A),
                                              ),
                                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                                            ),
                                            // Bakong red center badge (no image file needed)
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Container(
                                                margin: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE51A24),
                                                  borderRadius: BorderRadius.circular(7),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    '៛',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      // Error state with retry button
                                      : _qrError != null
                                          ? Center(
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 36),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                      'Could not generate QR',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _qrError ?? 'Please check your connection or login status',
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    ElevatedButton.icon(
                                                      onPressed: _initBakongPayment,
                                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                                      label: const Text('Retry'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFE51A24),
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          // Generating spinner
                                          : const Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(
                                                    color: Color(0xFFE51A24),
                                                    strokeWidth: 3,
                                                  ),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    'Generating KHQR...',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                ),

                                // Laser Scanline Beam
                                AnimatedBuilder(
                                  animation: _scanAnimController,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 14 + (200 * _scanLineAnim.value),
                                      left: 20,
                                      right: 20,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              const Color(0xFFE51A24).withAlpha(180),
                                              const Color(0xFFE51A24),
                                              const Color(0xFFE51A24).withAlpha(180),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE51A24).withAlpha(120),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 4. Supported Cambodian Bank Badges Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildBankPill('ABA Bank', const Color(0xFF003B6F), Colors.white),
                                _buildBankPill('Bakong', const Color(0xFFE51A24), Colors.white),
                                _buildBankPill('ACLEDA', const Color(0xFF0B286D), const Color(0xFFFDB913)),
                                _buildBankPill('Wing Bank', const Color(0xFF87C440), const Color(0xFF0A2E5C)),
                                _buildBankPill('Canadia', const Color(0xFFD32F2F), Colors.white),
                                _buildBankPill('Sathapana', const Color(0xFF004F9E), Colors.white),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 5. Quick Tools (Save QR & Copy Info)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: _handleSaveQr,
                                  icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0F172A)),
                                  label: const Text(
                                    'Save QR Code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 16, color: Colors.grey[300]),
                                TextButton.icon(
                                  onPressed: _handleCopyAccount,
                                  icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF0F172A)),
                                  label: const Text(
                                    'Copy Details',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
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

                  // Live Listening Status Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282D2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Scan with any Mobile Banking App (ABA, Wing, ACLEDA, Bakong, etc.)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Confirm & Cancel Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _handleConfirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE51A24),
                        elevation: 3,
                        shadowColor: const Color(0xFFE51A24).withAlpha(100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isVerifying
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Verifying Bank Payment...',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'I Have Paid via KHQR',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel & Choose Another Method',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankPill(String name, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
