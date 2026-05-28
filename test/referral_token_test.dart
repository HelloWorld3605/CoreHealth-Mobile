import 'package:corehealth_flutter/src/data/app_repository.dart';
import 'package:corehealth_flutter/src/data/memory_app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Referral and Token Registration Tests', () {
    late MemoryAppRepository repository;

    setUp(() {
      repository = MemoryAppRepository();
    });

    test('registering without a referral code grants 25 tokens and sets a referral code', () async {
      final regResult = await repository.register(
        displayName: 'Anh Tung',
        email: 'tung@example.com',
        password: 'password123',
      );

      final result = await repository.verifyOtp(
        email: 'tung@example.com',
        otp: regResult.devOtp!,
      );

      expect(result.session.email, equals('tung@example.com'));
      expect(result.userData.profile.tokenBalance, equals(25));
      expect(result.userData.profile.tokenEarned, equals(25));
      expect(result.userData.profile.referralCode, isNotEmpty);
      expect(result.userData.profile.referredBy, isEmpty);
    });

    test('registering with an invalid referral code throws AppAuthException', () async {
      expect(
        () => repository.register(
          displayName: 'Anh Nam',
          email: 'nam@example.com',
          password: 'password123',
          referralCode: 'INVALID-123456',
        ),
        throwsA(isA<AppAuthException>().having((e) => e.message, 'message', 'Mã giới thiệu không hợp lệ.')),
      );
    });

    test('registering with a valid referral code grants 65 tokens to referred and links referredBy', () async {
      // 1. Register Referrer A
      final referrerReg = await repository.register(
        displayName: 'Referrer A',
        email: 'referrer_a@example.com',
        password: 'password123',
      );
      final referrerRes = await repository.verifyOtp(
        email: 'referrer_a@example.com',
        otp: referrerReg.devOtp!,
      );
      final refCode = referrerRes.userData.profile.referralCode;

      // 2. Register Referred B with refCode
      final referredReg = await repository.register(
        displayName: 'Referred B',
        email: 'referred_b@example.com',
        password: 'password123',
        referralCode: refCode,
      );
      final referredRes = await repository.verifyOtp(
        email: 'referred_b@example.com',
        otp: referredReg.devOtp!,
      );

      expect(referredRes.userData.profile.tokenBalance, equals(65));
      expect(referredRes.userData.profile.tokenEarned, equals(65));
      expect(referredRes.userData.profile.referredBy, equals(referrerRes.session.userId));
    });

    test('registering yourself with your own referral code throws AppAuthException', () async {
      // 1. Register User A
      final reg = await repository.register(
        displayName: 'User A',
        email: 'usera@example.com',
        password: 'password123',
      );
      await repository.verifyOtp(
        email: 'usera@example.com',
        otp: reg.devOtp!,
      );
    });

    test('referrer receives +20 tokens on their 5th referred user (milestone)', () async {
      // 1. Register Referrer A
      final referrerReg = await repository.register(
        displayName: 'Referrer A',
        email: 'ref_milestone@example.com',
        password: 'password123',
      );
      final referrerRes = await repository.verifyOtp(
        email: 'ref_milestone@example.com',
        otp: referrerReg.devOtp!,
      );
      final refCode = referrerRes.userData.profile.referralCode;

      // 2. Register 4 referrals: A's balance should remain 25 tokens
      for (int i = 1; i <= 4; i++) {
        final reg = await repository.register(
          displayName: 'Friend $i',
          email: 'friend$i@example.com',
          password: 'password123',
          referralCode: refCode,
        );
        await repository.verifyOtp(
          email: 'friend$i@example.com',
          otp: reg.devOtp!,
        );
      }

      // Verify referrer A balance is still 25
      final loginRes = await repository.signIn(
        email: 'ref_milestone@example.com',
        password: 'password123',
      );
      expect(loginRes.userData.profile.tokenBalance, equals(25));

      // 3. Register the 5th referral
      final reg5 = await repository.register(
        displayName: 'Friend 5',
        email: 'friend5@example.com',
        password: 'password123',
        referralCode: refCode,
      );
      await repository.verifyOtp(
        email: 'friend5@example.com',
        otp: reg5.devOtp!,
      );

      // Verify referrer A balance is now 25 + 20 = 45 tokens
      final loginResAfter = await repository.signIn(
        email: 'ref_milestone@example.com',
        password: 'password123',
      );
      expect(loginResAfter.userData.profile.tokenBalance, equals(45));
      expect(loginResAfter.userData.profile.tokenEarned, equals(45));
    });
  });
}
