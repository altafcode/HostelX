import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/stripe_config.dart';

class StripeCheckoutSession {
  final String id;
  final String checkoutUrl;
  final String paymentStatus;

  const StripeCheckoutSession({
    required this.id,
    required this.checkoutUrl,
    required this.paymentStatus,
  });
}

class StripePayoutResult {
  final bool success;
  final String message;
  final String? transferId;

  const StripePayoutResult({
    required this.success,
    required this.message,
    this.transferId,
  });
}

class StripeService {
  Map<String, String> get _headers {
    final secret = StripeConfig.secretKey.trim();
    if (secret.isEmpty) {
      throw Exception(
        'Stripe secret key is missing. Run Flutter with STRIPE_SECRET_KEY configured.',
      );
    }

    return {
      'Authorization': 'Bearer $secret',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  int _toStripeAmount(num amount) {
    return (amount * 100).round();
  }

  Future<StripeCheckoutSession> createCheckoutSession({
    required int amount,
    required String hostelName,
    required String roomNumber,
    required String userId,
    required String userName,
    required String bookingReference,
  }) async {
    final response = await http.post(
      Uri.parse('${StripeConfig.apiBaseUrl}/checkout/sessions'),
      headers: _headers,
      body: {
        'mode': 'payment',
        'payment_method_types[]': 'card',
        'success_url':
            '${StripeConfig.checkoutSuccessUrl}?session_id={CHECKOUT_SESSION_ID}',
        'cancel_url': StripeConfig.checkoutCancelUrl,
        'line_items[0][quantity]': '1',
        'line_items[0][price_data][currency]': StripeConfig.currency,
        'line_items[0][price_data][unit_amount]':
            _toStripeAmount(amount).toString(),
        'line_items[0][price_data][product_data][name]':
            '$hostelName - Room $roomNumber',
        'metadata[user_id]': userId,
        'metadata[user_name]': userName,
        'metadata[booking_reference]': bookingReference,
      },
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = json['error'] is Map<String, dynamic>
          ? json['error']['message']?.toString()
          : null;
      throw Exception(message ?? 'Stripe checkout session failed.');
    }

    final url = json['url']?.toString();
    final id = json['id']?.toString();
    if (url == null || id == null) {
      throw Exception('Stripe did not return a checkout URL.');
    }

    return StripeCheckoutSession(
      id: id,
      checkoutUrl: url,
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
    );
  }

  Future<StripeCheckoutSession> retrieveCheckoutSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('${StripeConfig.apiBaseUrl}/checkout/sessions/$sessionId'),
      headers: _headers,
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final message = json['error'] is Map<String, dynamic>
          ? json['error']['message']?.toString()
          : null;
      throw Exception(message ?? 'Unable to verify Stripe payment.');
    }

    return StripeCheckoutSession(
      id: json['id']?.toString() ?? sessionId,
      checkoutUrl: json['url']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
    );
  }

  Future<StripePayoutResult> releaseOwnerPayout({
    required double amount,
    required String connectedAccountId,
    required String ownerId,
    required String ownerName,
  }) async {
    if (amount <= 0) {
      return const StripePayoutResult(
        success: false,
        message: 'No payout amount is available for this owner.',
      );
    }

    if (connectedAccountId.trim().isEmpty) {
      return const StripePayoutResult(
        success: false,
        message: 'Owner Stripe connected account ID is missing.',
      );
    }

    final response = await http.post(
      Uri.parse('${StripeConfig.apiBaseUrl}/transfers'),
      headers: _headers,
      body: {
        'amount': _toStripeAmount(amount).toString(),
        'currency': StripeConfig.currency,
        'destination': connectedAccountId.trim(),
        'description': 'HostelX owner payout for $ownerName',
        'metadata[owner_id]': ownerId,
        'metadata[owner_name]': ownerName,
      },
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = json['error'] is Map<String, dynamic>
          ? json['error']['message']?.toString()
          : null;
      return StripePayoutResult(
        success: false,
        message: message ?? 'Stripe payout transfer failed.',
      );
    }

    return StripePayoutResult(
      success: true,
      message: 'Payout released to the owner Stripe balance.',
      transferId: json['id']?.toString(),
    );
  }
}
