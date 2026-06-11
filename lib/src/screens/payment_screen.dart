import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/environment_config.dart';
import '../services/sepay_service.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.amountK,
    required this.description,
    required this.onSuccess,
    this.onTimeout,
  });

  /// Amount in thousands of VNĐ.
  final int amountK;

  /// Short description shown at the top.
  final String description;

  /// Called once payment is confirmed. Caller does the actual business action.
  final VoidCallback onSuccess;

  /// Called when payment times out and user cancels. Optional.
  final VoidCallback? onTimeout;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

// ---------------------------------------------------------------------------
// Payment method definitions
// ---------------------------------------------------------------------------

enum _MethodGroup { wallet, international, bank }

class _PayMethod {
  const _PayMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.group,
    this.iosOnly = false,
    this.androidOnly = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final _MethodGroup group;
  final bool iosOnly;
  final bool androidOnly;
}

const _methods = <_PayMethod>[
  // --- Ví điện tử ---
  _PayMethod(
    id: 'momo',
    name: 'MoMo',
    subtitle: 'Ví điện tử phổ biến tại Việt Nam',
    color: Color(0xFFAE2070),
    icon: Icons.account_balance_wallet_rounded,
    group: _MethodGroup.wallet,
  ),
  _PayMethod(
    id: 'zalopay',
    name: 'ZaloPay',
    subtitle: 'Thanh toán qua ZaloPay',
    color: Color(0xFF0068FF),
    icon: Icons.account_balance_wallet_outlined,
    group: _MethodGroup.wallet,
  ),
  _PayMethod(
    id: 'vnpay',
    name: 'VNPay QR',
    subtitle: 'Quét QR – tương thích mọi ngân hàng VN',
    color: Color(0xFF0A4396),
    icon: Icons.qr_code_2_rounded,
    group: _MethodGroup.wallet,
  ),
  // --- Quốc tế ---
  _PayMethod(
    id: 'paypal',
    name: 'PayPal',
    subtitle: 'Thẻ tín dụng & tài khoản PayPal quốc tế',
    color: Color(0xFF003087),
    icon: Icons.language_rounded,
    group: _MethodGroup.international,
  ),
  _PayMethod(
    id: 'applepay',
    name: 'Apple Pay',
    subtitle: 'Thanh toán nhanh bằng Face ID / Touch ID',
    color: Colors.black,
    icon: Icons.apple_rounded,
    group: _MethodGroup.international,
    iosOnly: true,
  ),
  _PayMethod(
    id: 'googlepay',
    name: 'Google Pay',
    subtitle: 'Thanh toán nhanh bằng Google Wallet',
    color: Color(0xFF4285F4),
    icon: Icons.g_mobiledata_rounded,
    group: _MethodGroup.international,
    androidOnly: true,
  ),
  // --- Ngân hàng ---
  _PayMethod(
    id: 'vcb',
    name: 'Vietcombank',
    subtitle: 'Chuyển khoản ngân hàng',
    color: Color(0xFF007B40),
    icon: Icons.account_balance_rounded,
    group: _MethodGroup.bank,
  ),
  _PayMethod(
    id: 'bidv',
    name: 'BIDV',
    subtitle: 'Chuyển khoản ngân hàng',
    color: Color(0xFF005BAA),
    icon: Icons.account_balance_rounded,
    group: _MethodGroup.bank,
  ),
  _PayMethod(
    id: 'tcb',
    name: 'Techcombank',
    subtitle: 'Chuyển khoản ngân hàng',
    color: Color(0xFFE30613),
    icon: Icons.account_balance_rounded,
    group: _MethodGroup.bank,
  ),
  _PayMethod(
    id: 'mb',
    name: 'MB Bank',
    subtitle: 'Chuyển khoản ngân hàng',
    color: Color(0xFF6A1B9A),
    icon: Icons.account_balance_rounded,
    group: _MethodGroup.bank,
  ),
  _PayMethod(
    id: 'vpb',
    name: 'VPBank',
    subtitle: 'Chuyển khoản ngân hàng',
    color: Color(0xFF003DA5),
    icon: Icons.account_balance_rounded,
    group: _MethodGroup.bank,
  ),
  _PayMethod(
    id: 'acb',
    name: 'ACB',
    subtitle: 'Chuyển khoản ngân hàng',
    color: Color(0xFFF5A623),
    icon: Icons.account_balance_rounded,
    group: _MethodGroup.bank,
  ),
];

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum _PayState { selecting, awaitingPayment, processing, success, timeout }

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  _PayMethod? _selected;
  _PayState _state = _PayState.selecting;
  late final String _txId;
  late final String _reference;
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  Timer? _pollTimer;
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  int _waitedSeconds = 0;

  static const _timeoutSeconds = 600;

  // Bank methods and VNPay use real SePay QR polling
  bool get _isRealPayment =>
      _selected != null &&
      (_selected!.group == _MethodGroup.bank || _selected!.id == 'vnpay');

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _txId =
        'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}'
        '${rng.nextInt(9000) + 1000}';
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final rand = (rng.nextInt(9000) + 1000).toString();
    _reference = 'CH$dd$mm$rand'; // e.g. CH18047823 — dễ nhập tay
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _closeWs();
    _successCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    _waitedSeconds = 0;
    // Real-time path: listen for the backend's payment_confirmed push.
    unawaited(_connectWs());
    // Fallback path: poll /payments/verify in case the socket is unavailable.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _waitedSeconds += 3;
      if (_waitedSeconds >= _timeoutSeconds) {
        _pollTimer?.cancel();
        _closeWs();
        if (mounted) setState(() => _state = _PayState.timeout);
        return;
      }
      if (mounted) setState(() {}); // refresh counter
      final paid = await SepayService.instance.checkPaymentReceived(
        reference: _reference,
        amountVnd: widget.amountK * 1000,
      );
      if (paid) _onPaid();
    });
  }

  /// Shared success handler — invoked by either the WebSocket push or the poll.
  void _onPaid() {
    if (!mounted || _state == _PayState.success) return;
    _pollTimer?.cancel();
    _closeWs();
    widget.onSuccess();
    setState(() => _state = _PayState.success);
    _successCtrl.forward();
  }

  // Real-time payment notifications: wss://<host>/ws/payments?reference=...
  // Connect, authenticate with the JWT, then wait for payment_confirmed.
  Future<void> _connectWs() async {
    try {
      final jwt = await const FlutterSecureStorage().read(key: 'corehealth_jwt');
      if (jwt == null || jwt.isEmpty) return; // unauthenticated → poll only
      final channel = WebSocketChannel.connect(Uri.parse(_wsUrl(_reference)));
      _ws = channel;
      channel.sink.add(jsonEncode({'type': 'auth', 'token': jwt}));
      _wsSub = channel.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            if (msg is Map && msg['event'] == 'payment_confirmed') {
              _onPaid();
            }
          } catch (_) {/* ignore malformed frames */}
        },
        onError: (_) {/* socket failed → poll remains the fallback */},
        cancelOnError: true,
      );
    } catch (_) {/* connect failed → poll remains the fallback */}
  }

  void _closeWs() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.sink.close();
    _ws = null;
  }

  String _wsUrl(String reference) {
    // apiBaseUrl is https://host/api ; the socket lives at host root /ws/payments.
    var base = EnvironmentConfig.apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    base = base.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/ws/payments?reference=${Uri.encodeQueryComponent(reference)}';
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    if (_isRealPayment) {
      setState(() => _state = _PayState.awaitingPayment);
      _startPolling();
    } else {
      setState(() => _state = _PayState.processing);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      widget.onSuccess();
      setState(() => _state = _PayState.success);
      _successCtrl.forward();
    }
  }

  bool _visible(_PayMethod m) {
    if (m.iosOnly) return Theme.of(context).platform == TargetPlatform.iOS;
    if (m.androidOnly) {
      return Theme.of(context).platform == TargetPlatform.android;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _PayState.success) {
      return _SuccessScreen(
        txId: _txId,
        scale: _successScale,
        onDone: () => Navigator.of(context).pop(),
      );
    }
    if (_state == _PayState.timeout) {
      return _TimeoutScreen(
        reference: _reference,
        onRetry: () {
          setState(() {
            _state = _PayState.selecting;
            _selected = null;
          });
        },
        onClose: () {
          widget.onTimeout?.call();
          Navigator.of(context).pop();
        },
      );
    }
    if (_state == _PayState.awaitingPayment) {
      return _AwaitingPaymentScreen(
        amountK: widget.amountK,
        reference: _reference,
        waitedSeconds: _waitedSeconds,
        onCancel: () {
          _pollTimer?.cancel();
          _closeWs();
          setState(() => _state = _PayState.selecting);
        },
      );
    }
    return Stack(
      children: [
        _SelectingScreen(
          amountK: widget.amountK,
          description: widget.description,
          selected: _selected,
          reference: _reference,
          onSelect: (m) => setState(() => _selected = m),
          onConfirm: _selected != null ? _confirm : null,
          visible: _visible,
        ),
        if (_state == _PayState.processing) const _ProcessingOverlay(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Selecting screen
// ---------------------------------------------------------------------------

class _SelectingScreen extends StatelessWidget {
  const _SelectingScreen({
    required this.amountK,
    required this.description,
    required this.selected,
    required this.reference,
    required this.onSelect,
    required this.onConfirm,
    required this.visible,
  });

  final int amountK;
  final String description;
  final _PayMethod? selected;
  final String reference;
  final ValueChanged<_PayMethod> onSelect;
  final VoidCallback? onConfirm;
  final bool Function(_PayMethod) visible;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget section(String title, _MethodGroup group) {
      final items =
          _methods.where((m) => m.group == group && visible(m)).toList();
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
            child: Text(title,
                style: tt.bodySmall?.copyWith(
                    color: AppPalette.mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          ...items.map((m) => _MethodTile(
                method: m,
                selected: selected?.id == m.id,
                amountK: amountK,
                reference: reference,
                onTap: () => onSelect(m),
              )),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chọn phương thức thanh toán'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Amount header
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.emerald, AppPalette.emeraldDeep],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.payment_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description,
                          style: tt.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatAmount(amountK)} VNĐ',
                        style: tt.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Method list
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPadding,
                4,
                layout.horizontalPadding,
                bottomInset + 100,
              ),
              child: AdaptiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    section('VÍ ĐIỆN TỬ', _MethodGroup.wallet),
                    section('QUỐC TẾ', _MethodGroup.international),
                    section('NGÂN HÀNG VIỆT NAM', _MethodGroup.bank),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              layout.horizontalPadding, 10, layout.horizontalPadding, 14),
          child: AppActionButton(
            label: onConfirm != null
                ? 'Thanh toán ${_formatAmount(amountK)} VNĐ'
                : 'Chọn phương thức thanh toán',
            onPressed: onConfirm,
            icon: const Icon(Icons.payment_rounded),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual method tile
// ---------------------------------------------------------------------------

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.amountK,
    required this.reference,
    required this.onTap,
  });

  final _PayMethod method;
  final bool selected;
  final int amountK;
  final String reference;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? method.color : AppPalette.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: AppPalette.shadow, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: method.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(method.icon, color: method.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method.name,
                              style: tt.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(method.subtitle,
                              style: tt.bodySmall
                                  ?.copyWith(color: AppPalette.mutedText)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: selected ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: selected ? method.color : AppPalette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: selected
                  ? _MethodDetail(
                      method: method,
                      amountK: amountK,
                      reference: reference,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Method detail panel
// ---------------------------------------------------------------------------

class _MethodDetail extends StatelessWidget {
  const _MethodDetail({
    required this.method,
    required this.amountK,
    required this.reference,
  });

  final _PayMethod method;
  final int amountK;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    Widget divider() => Divider(
        height: 1,
        color: method.color.withValues(alpha: 0.12),
        indent: 14,
        endIndent: 14);

    // MoMo / ZaloPay — fake QR (not monitored by SePay)
    if (method.id == 'momo' || method.id == 'zalopay') {
      final phone = method.id == 'momo' ? '0901 234 567' : '0909 876 543';
      return Column(
        children: [
          divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                _FakeQrCode(seed: amountK, color: method.color),
                const SizedBox(height: 16),
                _InfoRow(label: 'Số điện thoại', value: phone, copyable: true),
                const _InfoRow(label: 'Tên tài khoản', value: 'CoreHealth VN'),
                _InfoRow(
                    label: 'Số tiền',
                    value: '${_formatAmount(amountK)} VNĐ',
                    highlight: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: method.color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quét mã QR bằng app ${method.name} rồi nhấn "Thanh toán".',
                          style: tt.bodySmall
                              ?.copyWith(color: method.color, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // VNPay QR — real VietQR preview (full confirmation via SePay polling)
    if (method.id == 'vnpay') {
      final qrUrl = SepayService.instance.vietQrUrl(
        amountVnd: amountK * 1000,
        reference: reference,
      );
      return Column(
        children: [
          divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                _VietQrImage(qrUrl: qrUrl, size: 180),
                const SizedBox(height: 10),
                Text('Quét bằng bất kỳ app ngân hàng Việt Nam',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: AppPalette.mutedText)),
                const SizedBox(height: 8),
                _InfoRow(
                    label: 'Số tiền',
                    value: '${_formatAmount(amountK)} VNĐ',
                    highlight: true),
                _InfoRow(
                    label: 'Nội dung CK', value: reference, copyable: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: method.color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhấn "Thanh toán" — app sẽ tự xác nhận khi nhận được tiền.',
                          style: tt.bodySmall
                              ?.copyWith(color: method.color, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // PayPal
    if (method.id == 'paypal') {
      return Column(
        children: [
          divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003087).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF003087).withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.language_rounded,
                          color: Color(0xFF003087), size: 36),
                      const SizedBox(height: 10),
                      Text('Thanh toán qua PayPal',
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF003087))),
                      const SizedBox(height: 4),
                      Text('pay@corehealth.vn',
                          style: tt.bodySmall
                              ?.copyWith(color: AppPalette.mutedText)),
                      const SizedBox(height: 6),
                      Text(
                          '${_formatAmount(amountK)} VNĐ ≈ \$${(amountK * 1000 / 25000).toStringAsFixed(2)} USD',
                          style: tt.bodySmall
                              ?.copyWith(color: AppPalette.mutedText)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sau khi nhấn "Thanh toán", ứng dụng sẽ mở PayPal để hoàn tất.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall
                      ?.copyWith(color: AppPalette.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Apple Pay / Google Pay
    if (method.id == 'applepay' || method.id == 'googlepay') {
      return Column(
        children: [
          divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: method.color.withValues(
                        alpha: method.id == 'applepay' ? 0.04 : 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: method.color.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Icon(method.icon, color: method.color, size: 36),
                      const SizedBox(height: 10),
                      Text(method.name,
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: method.color)),
                      const SizedBox(height: 4),
                      Text('${_formatAmount(amountK)} VNĐ',
                          style: tt.bodySmall
                              ?.copyWith(color: AppPalette.mutedText)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  method.id == 'applepay'
                      ? 'Xác thực bằng Face ID hoặc Touch ID khi nhấn "Thanh toán".'
                      : 'Xác thực bằng Google Wallet khi nhấn "Thanh toán".',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall
                      ?.copyWith(color: AppPalette.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Bank transfer — all banks point to same SePay-monitored MB Bank account
    return Column(
      children: [
        divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(color: method.color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(method.name,
                      style: tt.titleSmall?.copyWith(
                          color: method.color, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 14),
              _InfoRow(
                  label: 'Ngân hàng nhận',
                  value: SepayService.instance.bankName),
              _InfoRow(
                  label: 'Số tài khoản',
                  value: SepayService.instance.accountNumber,
                  copyable: true),
              _InfoRow(
                  label: 'Chủ tài khoản',
                  value: SepayService.instance.accountOwner),
              _InfoRow(
                  label: 'Số tiền',
                  value: '${_formatAmount(amountK)} VNĐ',
                  highlight: true),
              _InfoRow(label: 'Nội dung CK', value: reference, copyable: true),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppPalette.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhấn "Thanh toán" — app sẽ hiện QR và tự xác nhận khi nhận được tiền.',
                        style: tt.bodySmall
                            ?.copyWith(color: AppPalette.orange, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Awaiting payment screen (real SePay polling)
// ---------------------------------------------------------------------------

class _AwaitingPaymentScreen extends StatelessWidget {
  const _AwaitingPaymentScreen({
    required this.amountK,
    required this.reference,
    required this.waitedSeconds,
    required this.onCancel,
  });

  final int amountK;
  final String reference;
  final int waitedSeconds;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);
    final qrUrl = SepayService.instance.vietQrUrl(
      amountVnd: amountK * 1000,
      reference: reference,
    );

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Quét mã QR để thanh toán'),
        leading: BackButton(onPressed: onCancel),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          layout.horizontalPadding,
          8,
          layout.horizontalPadding,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: AdaptiveContent(
          child: Column(
            children: [
              // QR card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                        color: AppPalette.shadow,
                        blurRadius: 16,
                        offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    _VietQrImage(qrUrl: qrUrl, size: 220),
                    const SizedBox(height: 12),
                    Text('Quét bằng bất kỳ app ngân hàng Việt Nam',
                        style:
                            tt.bodySmall?.copyWith(color: AppPalette.mutedText),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bank info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Ngân hàng',
                        value: SepayService.instance.bankName),
                    _InfoRow(
                        label: 'Số tài khoản',
                        value: SepayService.instance.accountNumber,
                        copyable: true),
                    _InfoRow(
                        label: 'Chủ tài khoản',
                        value: SepayService.instance.accountOwner),
                    _InfoRow(
                        label: 'Số tiền',
                        value: '${_formatAmount(amountK)} VNĐ',
                        highlight: true),
                    _InfoRow(
                        label: 'Nội dung CK', value: reference, copyable: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Polling status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppPalette.emeraldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppPalette.emerald, strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đang chờ... Đã chờ: ${waitedSeconds}s • Kiểm tra mỗi 3s',
                        style: tt.bodySmall
                            ?.copyWith(color: AppPalette.emeraldDeep),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.orangeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppPalette.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nhập đúng nội dung "$reference" để đơn hàng được xác nhận tự động.',
                        style: tt.bodySmall
                            ?.copyWith(color: AppPalette.orange, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VietQR image widget
// ---------------------------------------------------------------------------

class _VietQrImage extends StatelessWidget {
  const _VietQrImage({required this.qrUrl, required this.size});

  final String qrUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: qrUrl,
      width: size,
      height: size,
      placeholder: (_, __) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: CircularProgressIndicator(
              color: AppPalette.emerald, strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(Icons.qr_code_2_rounded,
              size: 80, color: AppPalette.mutedText),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeout screen
// ---------------------------------------------------------------------------

class _TimeoutScreen extends StatelessWidget {
  const _TimeoutScreen({
    required this.reference,
    required this.onRetry,
    required this.onClose,
  });

  final String reference;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppPalette.orangeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: AppPalette.orange, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Hết thời gian chờ',
                  style: tt.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Không nhận được thanh toán sau 10 phút.',
                style: tt.bodyMedium?.copyWith(color: AppPalette.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Mã đơn: $reference',
                style: tt.bodySmall?.copyWith(
                    color: AppPalette.mutedText, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppActionButton(
                label: 'Thử lại',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(height: 12),
              AppActionButton(
                label: 'Huỷ đơn hàng',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                variant: AppActionButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row with optional copy
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: tt.bodySmall?.copyWith(color: AppPalette.mutedText)),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? AppPalette.emeraldDeep : AppPalette.text,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép: $value'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded,
                  size: 16, color: AppPalette.mutedText),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fake QR code (MoMo / ZaloPay only — not connected to SePay)
// ---------------------------------------------------------------------------

class _FakeQrCode extends StatelessWidget {
  const _FakeQrCode({required this.seed, required this.color});

  final int seed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(180, 180),
      painter: _QrPainter(seed: seed, color: color),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({required this.seed, required this.color});

  final int seed;
  final Color color;

  static const _size = 21;

  bool _cell(int r, int c, math.Random rng) {
    bool finder(int br, int bc) {
      final dr = r - br, dc = c - bc;
      if (dr < 0 || dr > 6 || dc < 0 || dc > 6) return false;
      if (dr == 0 || dr == 6 || dc == 0 || dc == 6) return true;
      if (dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4) return true;
      return false;
    }

    if (finder(0, 0) || finder(0, _size - 7) || finder(_size - 7, 0)) {
      return true;
    }
    if (r == 6 && c > 7 && c < _size - 7) return c % 2 == 0;
    if (c == 6 && r > 7 && r < _size - 7) return r % 2 == 0;
    return rng.nextBool();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final cellSz = size.width / _size;
    final paint = Paint()..color = color;
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_cell(r, c, rng)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  c * cellSz + 1, r * cellSz + 1, cellSz - 2, cellSz - 2),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.seed != seed || old.color != color;
}

// ---------------------------------------------------------------------------
// Processing overlay (mock methods only)
// ---------------------------------------------------------------------------

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: AppPalette.emerald, strokeWidth: 3),
                const SizedBox(height: 20),
                Text('Đang xử lý thanh toán...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Vui lòng không thoát màn hình',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppPalette.mutedText)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success screen
// ---------------------------------------------------------------------------

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({
    required this.txId,
    required this.scale,
    required this.onDone,
  });

  final String txId;
  final Animation<double> scale;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppPalette.emeraldSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppPalette.emerald, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text('Thanh toán thành công!',
                  style: tt.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('Giao dịch của bạn đã được xác nhận.',
                  style: tt.bodyMedium?.copyWith(color: AppPalette.mutedText),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.border),
                  boxShadow: const [
                    BoxShadow(
                        color: AppPalette.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mã giao dịch',
                        style: tt.bodySmall
                            ?.copyWith(color: AppPalette.mutedText)),
                    Text(txId,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppActionButton(
                label: 'Hoàn tất',
                onPressed: onDone,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatAmount(int amountK) {
  if (amountK >= 1000) {
    final millions = amountK ~/ 1000;
    final remainder = amountK % 1000;
    if (remainder == 0) return '$millions.000.000';
    return '$millions.${remainder.toString().padLeft(3, '0')}.000';
  }
  return '$amountK.000';
}
