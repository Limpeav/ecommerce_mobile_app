/// Application-wide environment configuration using compile-time constants.
///
/// Can be overridden during build or run:
/// ```bash
/// flutter run --dart-define=BASE_URL=https://staging.example.com --dart-define=APP_ENV=staging
/// ```
class AppConfig {
  /// Base API URL for backend services
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://backend-80bu.onrender.com',
  );

  /// Google Maps API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBXva4PuRMiA-l2pgeSCSwxabTPG6FoupY',
  );

  /// Deployment environment: 'production', 'staging', or 'development'
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  /// Default Bakong merchant account ID
  static const String defaultBakongMerchant = String.fromEnvironment(
    'BAKONG_MERCHANT_ID',
    defaultValue: 'cherish_baby@abaa',
  );

  /// Quick environment checks
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'development';
}
