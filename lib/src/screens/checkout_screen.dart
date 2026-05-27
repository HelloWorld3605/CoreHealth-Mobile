import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';
import 'payment_screen.dart';

String _fmtVnd(int priceK) {
  final s = (priceK * 1000).toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()}đ';
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalK,
    required this.onSuccess,
    this.onTimeout,
  });

  final List<Product> items;
  final int totalK;
  final VoidCallback onSuccess;
  final VoidCallback? onTimeout;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          amountK: widget.totalK,
          description: 'Đặt hàng CoreHealth Shop',
          onSuccess: () {
            widget.onSuccess();
            Navigator.of(context).pop();
          },
          onTimeout: widget.onTimeout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: const CoreHealthSubPageAppBar(title: 'Xác nhận đơn hàng'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            layout.horizontalPadding,
            8,
            layout.horizontalPadding,
            120,
          ),
          child: AdaptiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order summary header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.items.length} sản phẩm',
                              style: tt.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            Text(
                              _fmtVnd(widget.totalK),
                              style: tt.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Items list
                const SectionHeading(
                  title: 'Sản phẩm đặt mua',
                  icon: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppPalette.emerald,
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < widget.items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: AppPalette.border.withValues(alpha: 0.5),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.items[i].nameVi,
                                      style: tt.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.items[i].unit,
                                      style: tt.bodySmall?.copyWith(
                                        color: AppPalette.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _fmtVnd(widget.items[i].priceK),
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Divider(
                        height: 1,
                        color: AppPalette.border.withValues(alpha: 0.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng cộng',
                              style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _fmtVnd(widget.totalK),
                              style: tt.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppPalette.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Delivery info
                const SectionHeading(
                  title: 'Thông tin nhận hàng',
                  icon: Icon(
                    Icons.local_shipping_outlined,
                    color: AppPalette.blue,
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      _DeliveryField(
                        controller: _nameCtrl,
                        label: 'Họ và tên',
                        hint: 'Nguyễn Văn A',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập họ tên'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _DeliveryField(
                        controller: _phoneCtrl,
                        label: 'Số điện thoại',
                        hint: '0901 234 567',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 9)
                            ? 'Vui lòng nhập số điện thoại'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _DeliveryField(
                        controller: _addressCtrl,
                        label: 'Địa chỉ giao hàng',
                        hint: '123 Đường ABC, Quận 1, TP.HCM',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập địa chỉ'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              layout.horizontalPadding, 10, layout.horizontalPadding, 14),
          child: AppActionButton(
            label: 'Tiến hành thanh toán • ${_fmtVnd(widget.totalK)}',
            onPressed: _proceedToPayment,
            icon: const Icon(Icons.payment_rounded),
          ),
        ),
      ),
    );
  }
}

class _DeliveryField extends StatelessWidget {
  const _DeliveryField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppPalette.mutedText),
            const SizedBox(width: 6),
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: tt.bodyMedium?.copyWith(color: AppPalette.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium?.copyWith(color: AppPalette.subtleText),
            filled: true,
            fillColor: AppPalette.surfaceElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.emerald, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
