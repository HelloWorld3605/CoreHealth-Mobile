import 'package:corehealth_flutter/src/models.dart';
import 'package:corehealth_flutter/src/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('server-created orders hide simulated payment methods',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentScreen(
          amountK: 49,
          description: 'Starter token pack - 55 token',
          paymentOrder: const PaymentOrder(
            orderId: 'topup-1',
            reference: 'CH12069999',
            qrUrl: 'https://qr.example/CH12069999',
            bankName: 'MB Bank',
            accountNumber: '123456',
            accountOwner: 'COREHEALTH',
            expiresAt: '2026-06-12T10:00:00Z',
            amountVnd: 49000,
            packId: 'starter',
            tokenAmount: 55,
          ),
          onSuccess: () {},
        ),
      ),
    );

    expect(find.text('VNPay QR'), findsOneWidget);
    expect(find.text('MB Bank'), findsOneWidget);
    expect(find.text('MoMo'), findsNothing);
    expect(find.text('PayPal'), findsNothing);
  });
}
