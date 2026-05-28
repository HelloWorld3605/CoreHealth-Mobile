import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  // Mock list of orders for the mockup screen
  static const List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 'ODR-89472',
      'date': '24/05/2026',
      'items': [
        {'name': 'Whey Protein Isolate 2kg', 'quantity': 1, 'priceK': 1250},
        {'name': 'Dây kháng lực tập mông', 'quantity': 2, 'priceK': 120}
      ],
      'status': 'Đang giao hàng',
      'totalK': 1490
    },
    {
      'id': 'ODR-74829',
      'date': '12/05/2026',
      'items': [
        {'name': 'Bột yến mạch organic 1kg', 'quantity': 3, 'priceK': 95},
        {'name': 'Hạt chia hữu cơ 250g', 'quantity': 1, 'priceK': 140}
      ],
      'status': 'Đã hoàn thành',
      'totalK': 425
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Đơn hàng của tôi'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _mockOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, idx) {
          final order = _mockOrders[idx];
          final isDelivered = order['status'] == 'Đã hoàn thành';

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: AppPalette.mutedText),
                        const SizedBox(width: 8),
                        Text(
                          order['id'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDelivered ? AppPalette.emeraldSoft : AppPalette.orangeSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order['status'],
                        style: TextStyle(
                          color: isDelivered ? AppPalette.emeraldDeep : AppPalette.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Item preview
                ...List.generate(
                  (order['items'] as List).length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${order['items'][i]['name']} x${order['items'][i]['quantity']}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng số tiền: ${order['totalK']}k VNĐ',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Ngày đặt: ${order['date']}',
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
