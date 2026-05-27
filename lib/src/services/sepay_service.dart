import 'dart:convert';

import 'package:http/http.dart' as http;

/// SePay payment verification service.
/// Build with: --dart-define=SEPAY_API_TOKEN=<token>
///
/// Flow:
///   1. Generate a unique reference (e.g. CH1748123456).
///   2. Display a VietQR code via [vietQrUrl] — user scans with any VN banking app.
///   3. Poll [checkPaymentReceived] every few seconds until amount_in matches.
///
/// Production note: move the token to your backend proxy so it's never
/// bundled in the APK/IPA.  The app would call
///   POST /api/payments/verify?reference=CH...&amount=99000
/// and the backend calls SePay.
class SepayService {
  SepayService._();

  static final SepayService instance = SepayService._();

  // Injected at build time: --dart-define=SEPAY_API_TOKEN=xxx
  static const _token =
      String.fromEnvironment('SEPAY_API_TOKEN', defaultValue: '');

  static const _account = '4444815072005';
  static const _bankId = 'MB';
  static const _accountName = 'NGUYEN HUU TUNG';
  static const _baseUrl = 'https://my.sepay.vn/userapi';

  // -------------------------------------------------------------------------
  // VietQR image URL (works with all VN banking apps, MoMo, ZaloPay, etc.)
  // -------------------------------------------------------------------------

  String vietQrUrl({required int amountVnd, required String reference}) {
    final info = Uri.encodeComponent(reference);
    final name = Uri.encodeComponent(_accountName);
    return 'https://img.vietqr.io/image/$_bankId-$_account-qr_only.png'
        '?amount=$amountVnd&addInfo=$info&accountName=$name';
  }

  // -------------------------------------------------------------------------
  // Check if a payment with this reference has arrived
  // -------------------------------------------------------------------------

  /// Returns `true` when a transaction whose `transaction_content` contains
  /// [reference] (case-insensitive) and whose [amount_in] >= [amountVnd].
  Future<bool> checkPaymentReceived({
    required String reference,
    required int amountVnd,
  }) async {
    if (_token.isEmpty) return false; // token not injected — skip
    try {
      final uri = Uri.parse(
        '$_baseUrl/transactions/list'
        '?account_number=$_account&limit=20&sort=DESC',
      );
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $_token'})
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return false;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final transactions = body['transactions'] as List? ?? [];
      final refLower = reference.toLowerCase();

      for (final tx in transactions) {
        final content =
            (tx['transaction_content'] as String? ?? '').toLowerCase();
        final amountIn = (tx['amount_in'] as num? ?? 0).toInt();
        if (content.contains(refLower) && amountIn >= amountVnd) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String get accountNumber => _account;
  String get bankName => 'MB Bank';
  String get accountOwner => _accountName;
}
