import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/telegram_constants.dart';
import '../models/order.dart';

class TelegramBotService {
  /// Send a custom HTML message to the configured Telegram Chat & Thread
  static Future<bool> sendMessage({
    required String text,
    String? botToken,
    String? chatId,
    String? threadId,
    bool disableWebPagePreview = false,
  }) async {
    final token = (botToken != null && botToken.isNotEmpty)
        ? botToken
        : TelegramConstants.botToken;
    final targetChatId = (chatId != null && chatId.isNotEmpty)
        ? chatId
        : TelegramConstants.chatId;
    final targetThreadId = (threadId != null && threadId.isNotEmpty)
        ? threadId
        : TelegramConstants.threadId;

    if (token.isEmpty || targetChatId.isEmpty) {
      debugPrint('⚠️ TelegramBotService: botToken or chatId is not configured.');
      return false;
    }

    try {
      final url = Uri.parse('https://api.telegram.org/bot$token/sendMessage');

      final Map<String, dynamic> body = {
        'chat_id': targetChatId,
        'text': text,
        'parse_mode': 'HTML',
        'disable_web_page_preview': disableWebPagePreview,
      };

      // If message_thread_id (topic) is specified, include it
      if (targetThreadId.trim().isNotEmpty) {
        final parsedThreadId = int.tryParse(targetThreadId.trim());
        if (parsedThreadId != null) {
          body['message_thread_id'] = parsedThreadId;
        }
      }

      debugPrint('🔵 Dispatching Order to Telegram Bot (Chat: $targetChatId, Thread: $targetThreadId)...');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Telegram Bot notification sent successfully (HTTP ${response.statusCode})');
        return true;
      } else {
        debugPrint('⚠️ Telegram Bot API returned status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Error dispatching notification to Telegram Bot: $e');
      return false;
    }
  }

  /// Sends a notification formatted exactly as requested:
  ///
  /// NEW ORDER RECEIVED
  ///
  /// Order: D5C113D9
  /// Customer: Annie
  /// Phone: +85587822356
  /// Items: 1
  /// Total: $12.29
  /// Payment: Cash on Delivery
  /// Address: 157, 157, Bavel, Battambang Province, Cambodia, Bavel / Battambang Province
  /// Map: https://www.google.com/maps?q=13.255141286739391,102.8759079288331
  static Future<bool> sendOrderNotification({
    required OrderModel order,
    double exchangeRate = 4100.0,
    String? paymentStatusOverride,
    String? transactionId,
    String? threadIdOverride,
  }) async {
    try {
      final buffer = StringBuffer();

      // Extract coordinates if present in order or deliveryAddress
      double? lat = order.latitude;
      double? lng = order.longitude;
      String cleanAddress = order.deliveryAddress;

      final coordRegex = RegExp(r'\((-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)\)');
      final match = coordRegex.firstMatch(cleanAddress);
      if (match != null) {
        lat ??= double.tryParse(match.group(1)!);
        lng ??= double.tryParse(match.group(2)!);
        cleanAddress = cleanAddress.replaceAll(match.group(0)!, '').replaceAll(', ,', ',').trim();
      }

      // Clean trailing and leading commas/spaces
      cleanAddress = cleanAddress.replaceAll(RegExp(r'^,\s*|,\s*$'), '').trim();
      if (cleanAddress.isEmpty) {
        cleanAddress = 'Phnom Penh, Cambodia';
      }

      // Defaults if no coordinates are found
      lat ??= 11.5564;
      lng ??= 104.9282;

      // Customer info
      final customerName = order.recipientName?.isNotEmpty == true
          ? order.recipientName!
          : 'Customer';
      final phone = formatPhone(order.recipientPhone);

      // Total item quantity count
      final totalItemCount = order.items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );
      final itemsCountDisplay = totalItemCount > 0 ? totalItemCount : order.items.length;

      // Total price formatted
      final totalFormatted = '\$${order.total.toStringAsFixed(2)}';

      // Payment method display
      final isCod = order.paymentMethod.toUpperCase().contains('CASH') ||
          order.paymentMethod.toUpperCase().contains('COD');
      final paymentDisplay = isCod ? 'Cash on Delivery' : 'Bakong KHQR';

      // Order code (e.g. D5C113D9)
      final orderCode = order.displayOrderCode;

      // Construct message matching the exact screenshot layout
      buffer.writeln('<b>NEW ORDER RECEIVED</b>');
      buffer.writeln('');
      buffer.writeln('<b>Order:</b> $orderCode');
      buffer.writeln('<b>Customer:</b> $customerName');
      buffer.writeln('<b>Phone:</b> $phone');
      buffer.writeln('<b>Items:</b> $itemsCountDisplay');
      buffer.writeln('<b>Total:</b> $totalFormatted');
      buffer.writeln('<b>Payment:</b> $paymentDisplay');
      buffer.writeln('<b>Address:</b> $cleanAddress');
      buffer.write('<b>Map:</b> https://www.google.com/maps?q=$lat,$lng');

      return await sendMessage(
        text: buffer.toString(),
        threadId: threadIdOverride,
        disableWebPagePreview: false, // Allows the rich Google Maps preview card
      );
    } catch (e) {
      debugPrint('⚠️ Error generating Telegram order notification: $e');
      return false;
    }
  }

  /// Format phone numbers into standard +855XXXXXXXX format
  static String formatPhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '+85516568335';
    var p = raw.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    if (p.startsWith('+855')) return p;
    if (p.startsWith('855')) return '+$p';
    if (p.startsWith('0')) return '+855${p.substring(1)}';
    return '+855$p';
  }
}
