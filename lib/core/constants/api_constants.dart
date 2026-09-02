import 'app_config.dart';

class ApiConstants {
  static const String baseUrl = AppConfig.baseUrl;
  static const String products = '${AppConfig.baseUrl}/api/products';
  static const String singleProduct = '${AppConfig.baseUrl}/api/products';
  static String productReviews(String productId) => '$products/$productId/reviews';
  static const String banners = '${AppConfig.baseUrl}/api/banners';
  // Orders API Endpoints (Mapped directly to backend orderRoutes.js)
  static const String orders = '${AppConfig.baseUrl}/api/orders';
  static const String myOrders = '$orders/myorders';
  static const String orderStats = '$orders/stats';
  static const String pendingReviews = '$orders/pending-reviews';
  static String trackOrder(String orderNumber) => '$orders/track/$orderNumber';
  static String orderById(String id) => '$orders/$id';
  static String payOrder(String id) => '$orders/$id/pay';
  static String cancelOrder(String id) => '$orders/$id/cancel';
  static String updateOrderStatus(String id) => '$orders/$id/status';
  static String updatePaymentStatus(String id) => '$orders/$id/payment-status';
  static String deliveryProof(String id) => '$orders/$id/delivery-proof';
  static String deliveryConfirmation(String id) => '$orders/$id/delivery-confirmation';
  static String receiptTelegram(String id) => '$orders/$id/receipt-telegram';

  // Wishlist API Endpoints
  static const String wishlist = '${AppConfig.baseUrl}/api/wishlist';
  static const String addToWishlist = '$wishlist/add';
  static String removeFromWishlist(String productId) => '$wishlist/remove/$productId';

  // Cart API Endpoints
  static const String cart = '${AppConfig.baseUrl}/api/cart';
  static const String addToCart = '$cart/add';
  static String removeFromCart(String productId) => '$cart/remove/$productId';
  static String updateCartQuantity(String productId) => '$cart/$productId';
  static const String clearCart = cart;

  // Payment API Endpoints (Securely handled by your backend)
  static const String payments = '${AppConfig.baseUrl}/api/payments';
  static const String generateBakongQR = '$payments/bakong/generate';
  static String paymentStatus(String paymentId) => '$payments/$paymentId/status';
  static String paymentByOrder(String orderId) => '$payments/order/$orderId';

  // Settings (admin-configured, public)
  static const String financialSettings = '${AppConfig.baseUrl}/api/settings/financial';

  // Google Maps API Key
  static const String googleMapsApiKey = AppConfig.googleMapsApiKey;
}
