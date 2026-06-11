import 'package:flutter/material.dart';
import '../app_controller.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = CoreHealthScope.of(context).orders;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Đơn hàng của tôi'),
      ),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 48, color: AppPalette.mutedText),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn chưa có đơn hàng nào.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final order = orders[idx];
                final isDelivered =
                    order.statusLabel.toLowerCase().contains('hoàn thành');

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded,
                                  color: AppPalette.mutedText),
                              const SizedBox(width: 8),
                              Text(
                                order.id,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDelivered
                                  ? AppPalette.emeraldSoft
                                  : AppPalette.orangeSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: TextStyle(
                                color: isDelivered
                                    ? AppPalette.emeraldDeep
                                    : AppPalette.orange,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${order.itemCount} sản phẩm',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng số tiền: ${order.totalK}k VNĐ',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Ngày đặt: ${order.dateLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
