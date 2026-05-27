import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';
import 'checkout_screen.dart';

String _fmtVnd(int priceK) {
  final s = (priceK * 1000).toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()}đ';
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedIds = {};
  bool _selectionSeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cart = CoreHealthScope.of(context).cart;
    final cartIds = cart.map((item) => item.id).toSet();

    if (cart.isEmpty) {
      _selectedIds.clear();
      _selectionSeeded = false;
      return;
    }

    if (!_selectionSeeded) {
      _selectedIds
        ..clear()
        ..addAll(cartIds);
      _selectionSeeded = true;
      return;
    }

    _selectedIds.removeWhere((id) => !cartIds.contains(id));
  }

  void _toggleItem(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleAll(List<Product> cart) {
    setState(() {
      if (_selectedIds.length == cart.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(cart.map((item) => item.id));
      }
      _selectionSeeded = true;
    });
  }

  void _removeSelected(AppController controller) {
    final productIds = controller.cart
        .where((item) => _selectedIds.contains(item.id))
        .map((item) => item.id)
        .toList();

    setState(() => _selectedIds.clear());
    for (final productId in productIds) {
      controller.removeCartItem(productId);
    }
  }

  void _openCheckout(
    BuildContext context,
    AppController controller,
    List<Product> selectedItems,
    int selectedTotalK,
  ) {
    final selectedIds = selectedItems.map((item) => item.id).toSet();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          items: selectedItems,
          totalK: selectedTotalK,
          onSuccess: () {
            controller.placeOrderItems(selectedIds);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đơn hàng ${selectedItems.length} sản phẩm đã được tạo.',
                ),
              ),
            );
          },
          onTimeout: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đơn hàng đã bị huỷ do không nhận được thanh toán.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final layout = PhoneLayout.of(context);
    final cart = controller.cart;
    final selectedItems =
        cart.where((item) => _selectedIds.contains(item.id)).toList();
    final selectedTotalK =
        selectedItems.fold<int>(0, (sum, item) => sum + item.priceK);
    final allSelected = cart.isNotEmpty && _selectedIds.length == cart.length;

    return Scaffold(
      appBar: const CoreHealthSubPageAppBar(title: 'Giỏ hàng & đơn hàng'),
      body: AdaptiveContent(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            layout.horizontalPadding,
            8,
            layout.horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(layout.isCompact ? 18 : 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giỏ hàng hiện tại',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cart.isEmpty
                          ? 'Chưa có sản phẩm nào'
                          : '${selectedItems.length}/${cart.length} đã chọn • ${_fmtVnd(selectedTotalK)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 18),
                    if (layout.isTiny)
                      Column(
                        children: [
                          AppActionButton(
                            label: selectedItems.isEmpty
                                ? 'Chọn sản phẩm'
                                : 'Đặt ${selectedItems.length} sản phẩm',
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () => _openCheckout(
                                      context,
                                      controller,
                                      selectedItems,
                                      selectedTotalK,
                                    ),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            variant: AppActionButtonVariant.secondary,
                            height: 48,
                          ),
                          const SizedBox(height: 10),
                          AppActionButton(
                            label: 'Xóa đã chọn',
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () => _removeSelected(controller),
                            icon: const Icon(Icons.delete_outline_rounded),
                            variant: AppActionButtonVariant.secondary,
                            height: 48,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: AppActionButton(
                              label: selectedItems.isEmpty
                                  ? 'Chọn sản phẩm'
                                  : 'Đặt ${selectedItems.length} sản phẩm',
                              onPressed: selectedItems.isEmpty
                                  ? null
                                  : () => _openCheckout(
                                        context,
                                        controller,
                                        selectedItems,
                                        selectedTotalK,
                                      ),
                              icon: const Icon(Icons.shopping_bag_outlined),
                              variant: AppActionButtonVariant.secondary,
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 132,
                            child: AppActionButton(
                              label: 'Xóa đã chọn',
                              onPressed: selectedItems.isEmpty
                                  ? null
                                  : () => _removeSelected(controller),
                              icon: const Icon(Icons.delete_outline_rounded),
                              variant: AppActionButtonVariant.secondary,
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: SectionHeading(
                      title: 'Sản phẩm trong giỏ',
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        color: AppPalette.orange,
                      ),
                    ),
                  ),
                  if (cart.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _toggleAll(cart),
                      icon: Icon(
                        allSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 18,
                      ),
                      label: Text(allSelected ? 'Bỏ chọn' : 'Chọn tất cả'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppPalette.emeraldDeep,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (cart.isEmpty)
                const AppEmptyState(
                  icon: Icons.shopping_cart_checkout_rounded,
                  title: 'Giỏ hàng đang trống',
                  message:
                      'Thêm nguyên liệu hoặc đồ tập từ cửa hàng để bắt đầu.',
                )
              else
                ...cart.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CartItemCard(
                          product: entry.value,
                          selected: _selectedIds.contains(entry.value.id),
                          onSelectedChanged: (selected) =>
                              _toggleItem(entry.value.id, selected),
                          onRemove: () {
                            setState(() => _selectedIds.remove(entry.value.id));
                            controller.removeCartItem(entry.value.id);
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 18),
              if (controller.orders.isNotEmpty) ...[
                const SectionHeading(
                  title: 'Đơn hàng đã lưu',
                  icon: Icon(
                    Icons.receipt_long_rounded,
                    color: AppPalette.blue,
                  ),
                ),
                const SizedBox(height: 14),
                ...controller.orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppPalette.blueSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppPalette.blue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${order.itemCount} sản phẩm • ${_fmtVnd(order.totalK)} • ${order.dateLabel}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.emeraldSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.product,
    required this.selected,
    required this.onSelectedChanged,
    required this.onRemove,
  });

  final Product product;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: BorderSide(
        color: selected ? AppPalette.emerald : AppPalette.borderLight,
        width: selected ? 1.4 : 1,
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            activeColor: AppPalette.emeraldDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) => onSelectedChanged(value ?? false),
          ),
          const SizedBox(width: 4),
          RemoteImage(
            url: product.imageUrl,
            height: 78,
            width: 78,
            radius: 18,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nameVi,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${product.unit} • ${_fmtVnd(product.priceK)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.mutedText,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}
