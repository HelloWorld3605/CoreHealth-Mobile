import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GHN (Giao Hàng Nhanh) shipping service.
///
/// Provides shipping fee calculation, order creation, and order tracking.
/// Build with: --dart-define=GHN_TOKEN=xxx --dart-define=GHN_SHOP_ID=xxx
class GhnService {
  GhnService._();
  static final GhnService instance = GhnService._();

  static const _token = String.fromEnvironment('GHN_TOKEN');
  static const _shopId = String.fromEnvironment('GHN_SHOP_ID');
  static const _shopPhone = String.fromEnvironment('GHN_SHOP_PHONE');
  static const _baseUrl = 'https://online-gateway.ghn.vn/shiip/public-api';

  bool get isConfigured => _token.isNotEmpty;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Token': _token,
  };

  Map<String, String> get _headersWithShop => {
    ..._headers,
    'ShopId': _shopId,
  };

  // --- Master Data ---

  /// Get list of provinces/cities.
  Future<List<Map<String, dynamic>>> getProvinces() async {
    if (!isConfigured) return [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/master-data/province'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('[GHN] getProvinces error: $e');
      return [];
    }
  }

  /// Get districts for a province.
  Future<List<Map<String, dynamic>>> getDistricts(int provinceId) async {
    if (!isConfigured) return [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/master-data/district?province_id=$provinceId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('[GHN] getDistricts error: $e');
      return [];
    }
  }

  /// Get wards for a district.
  Future<List<Map<String, dynamic>>> getWards(int districtId) async {
    if (!isConfigured) return [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/master-data/ward?district_id=$districtId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('[GHN] getWards error: $e');
      return [];
    }
  }

  // --- Shipping Fee ---

  /// Calculate shipping fee in VND.
  /// [weightGrams] is the total weight in grams.
  Future<int> calculateShippingFee({
    required int toDistrictId,
    required String toWardCode,
    required int weightGrams,
    int? fromDistrictId,
  }) async {
    if (!isConfigured) return 0;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/v2/shipping-order/fee'),
        headers: _headersWithShop,
        body: jsonEncode({
          'service_type_id': 2,
          if (fromDistrictId != null) 'from_district_id': fromDistrictId,
          'to_district_id': toDistrictId,
          'to_ward_code': toWardCode,
          'weight': weightGrams,
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return 0;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      return (data?['total'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('[GHN] calculateShippingFee error: $e');
      return 0;
    }
  }

  // --- Order Management ---

  /// Create a shipping order. Returns GHN order code or null on failure.
  Future<String?> createOrder({
    required String toName,
    required String toPhone,
    required String toAddress,
    required String toWardCode,
    required int toDistrictId,
    required int codAmount,
    required int weightGrams,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!isConfigured) return null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/v2/shipping-order/create'),
        headers: _headersWithShop,
        body: jsonEncode({
          'payment_type_id': 2,
          'required_note': 'KHONGCHOXEMHANG',
          'to_name': toName,
          'to_phone': toPhone,
          'to_address': toAddress,
          'to_ward_code': toWardCode,
          'to_district_id': toDistrictId,
          'cod_amount': codAmount,
          'weight': weightGrams,
          'length': 20,
          'width': 15,
          'height': 10,
          'service_type_id': 2,
          'items': items,
        }),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        debugPrint('[GHN] createOrder failed: ${res.body}');
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      return data?['order_code'] as String?;
    } catch (e) {
      debugPrint('[GHN] createOrder error: $e');
      return null;
    }
  }

  /// Get order detail by order code.
  Future<Map<String, dynamic>?> getOrderDetail(String orderCode) async {
    if (!isConfigured) return null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/v2/shipping-order/detail'),
        headers: _headersWithShop,
        body: jsonEncode({'order_code': orderCode}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return {
        'orderCode': data['order_code'],
        'status': data['status'],
        'statusLabel': _statusLabel(data['status'] as String? ?? ''),
        'toName': data['to_name'],
        'toPhone': data['to_phone'],
        'toAddress': data['to_address'],
        'codAmount': data['cod_amount'],
        'weight': data['weight'],
        'leadtime': data['leadtime'],
        'orderDate': data['order_date'],
        'finishDate': data['finish_date'],
      };
    } catch (e) {
      debugPrint('[GHN] getOrderDetail error: $e');
      return null;
    }
  }

  /// Vietnamese status labels matching the web backend.
  String _statusLabel(String status) {
    return switch (status) {
      'ready_to_pick' => 'Chờ lấy hàng',
      'picking' => 'Đang lấy hàng',
      'picked' => 'Đã lấy hàng',
      'storing' => 'Đang lưu kho',
      'transporting' => 'Đang vận chuyển',
      'sorting' => 'Đang phân loại',
      'delivering' => 'Đang giao hàng',
      'delivered' => 'Đã giao hàng',
      'delivery_fail' => 'Giao hàng thất bại',
      'waiting_to_return' => 'Chờ hoàn hàng',
      'return' => 'Đang hoàn hàng',
      'return_transporting' => 'Đang vận chuyển hoàn',
      'return_sorting' => 'Đang phân loại hoàn',
      'returning' => 'Đang hoàn hàng',
      'return_fail' => 'Hoàn hàng thất bại',
      'returned' => 'Đã hoàn hàng',
      'cancel' => 'Đã huỷ',
      'exception' => 'Ngoại lệ',
      'damage' => 'Hàng hư hỏng',
      'lost' => 'Hàng thất lạc',
      _ => status,
    };
  }

  String get shopPhone => _shopPhone;
}
