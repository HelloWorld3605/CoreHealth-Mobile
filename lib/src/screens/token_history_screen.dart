import 'dart:async';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';
import 'payment_screen.dart';

class TokenHistoryScreen extends StatelessWidget {
  const TokenHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final transactions = controller.tokenTransactions;
    final layout = PhoneLayout.of(context);

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Lịch sử nạp token'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppPalette.emeraldDeep,
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              layout.horizontalPadding,
              8,
              layout.horizontalPadding,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              AdaptiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WalletSummary(profile: controller.profile),
                    const SizedBox(height: 18),
                    if (transactions.isEmpty)
                      _EmptyHistory(onTopUp: () => _openQuickTopUp(context))
                    else ...[
                      Text(
                        'Giao dịch gần đây',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      ...transactions.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TransactionTile(transaction: transaction),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuickTopUp(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final pack = tokenPacks.firstWhere(
      (item) => item.recommended,
      orElse: () => tokenPacks.first,
    );
    unawaited(() async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final order = await controller.createTokenTopupOrder(pack);
      if (!context.mounted) return;
      if (order == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Không tạo được đơn nạp token. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentScreen(
            amountK: (order.amountVnd / 1000).ceil(),
            description: '${pack.title} token pack - ${pack.tokens} token',
            paymentOrder: order,
            onSuccess: () {
              unawaited(controller.refreshAccountFromBackend());
              Navigator.of(context).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã xác nhận nạp ${order.tokenAmount ?? pack.tokens} token.',
                  ),
                ),
              );
            },
          ),
        ),
      );
    }());
  }
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary({required this.profile});

  final DemoProfile profile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.text, Color(0xFF27324A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadowHeavy,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.emerald.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.toll_rounded,
                  color: AppPalette.emerald,
                ),
              ),
              const Spacer(),
              Text(
                'Số dư ví',
                style: tt.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${profile.tokenBalance} token',
            style: tt.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Đã nhận',
                  value: '${profile.tokenEarned}',
                  color: AppPalette.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Đã dùng',
                  value: '${profile.tokenSpent}',
                  color: AppPalette.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TokenTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppPalette.emeraldDeep : AppPalette.orange;
    final softColor = isCredit ? AppPalette.emeraldSoft : AppPalette.orangeSoft;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(transaction.createdAt),
                  style: tt.bodySmall?.copyWith(color: AppPalette.mutedText),
                ),
                if (transaction.priceK > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${transaction.priceK}k VNĐ',
                    style: tt.bodySmall?.copyWith(
                      color: AppPalette.subtleText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isCredit ? '+' : ''}${transaction.amount}',
            style: tt.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onTopUp});

  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      radius: 28,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppPalette.blueSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppPalette.blue,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Chưa có giao dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Các lần nạp token và quà tặng sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          AppActionButton(
            label: 'Nạp token',
            onPressed: onTopUp,
            icon: const Icon(Icons.toll_rounded),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$hour:$minute, $day/$month/${value.year}';
}
