import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'environment_config.dart';

/// Payment verification via the shared CoreHealth backend.
///
/// Flow:
///   1. Generate a unique reference (e.g. CH1748123456).
///   2. Display a VietQR code via [vietQrUrl] — user scans with any VN banking app.
///   3. Poll [checkPaymentReceived] which asks the backend (POST /payments/verify)
///      whether the matching transfer has arrived.
///
/// The SePay API token lives server-side only — it is never bundled in the app.
/// The bank account number/owner used to render the QR are public details.
///
/// NOTE: /payments/verify confirms an order that was created server-side. Full
/// auto-confirmation requires the create-order flow (GHN address + create-order);
/// until then this returns false (the UI falls back to manual confirmation).
class SepayService {
  SepayService._();

  static final SepayService instance = SepayService._();

  static const _storage = FlutterSecureStorage();
  static const _jwtKey = 'corehealth_jwt';

  // Public VietQR display details (NOT secrets).
  static const _account = String.fromEnvironment(
    'SEPAY_ACCOUNT_NUMBER',
    defaultValue: '4444815072005',
  );
  static const _bankId = String.fromEnvironment(
    'SEPAY_BANK_ID',
    defaultValue: 'MB',
  );
  static const _accountName = String.fromEnvironment(
    'SEPAY_ACCOUNT_NAME',
    defaultValue: 'NGUYEN HUU TUNG',
  );

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
  // Ask the backend whether this payment has arrived (server-side SePay check)
  // -------------------------------------------------------------------------

  Future<bool> checkPaymentReceived({
    required String reference,
    required int amountVnd,
  }) async {
    try {
      final jwt = await _storage.read(key: _jwtKey);
      if (jwt == null || jwt.isEmpty) return false;
      final res = await http
          .post(
            Uri.parse('${EnvironmentConfig.apiBaseUrl}/payments/verify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({'reference': reference, 'amountVnd': amountVnd}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body);
      return body is Map && body['paid'] == true;
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
