/// Telegram Bot configuration constants
///
/// Replace these values with your Telegram Bot Token, Chat ID, and Thread ID (Topic ID)
/// from your backend .env file.
class TelegramConstants {
  /// Telegram Bot Token obtained from @BotFather (e.g., '123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ')
  static const String botToken = '8276145784:AAEmKji06IBDkXtFeG_lcIYScRQanx5QdG0';

  /// Target Chat ID (Group ID, Channel ID, or Private Chat ID, e.g., '-1001234567890')
  static const String chatId = '-1004297681371';

  /// Message Thread ID / Topic ID for supergroups with forum topics enabled (optional, e.g. '2')
  /// Set to null or empty string if not using topics.
  static const String threadId = '3';

  /// Base Telegram Bot API URL
  static String get sendMessageUrl =>
      'https://api.telegram.org/bot$botToken/sendMessage';

  /// Whether Telegram bot notifications are currently configured with valid values
  static bool get isConfigured =>
      botToken.isNotEmpty &&
      !botToken.contains('example') &&
      chatId.isNotEmpty &&
      !chatId.contains('example');
}
