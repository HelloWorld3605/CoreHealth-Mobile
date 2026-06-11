import 'dart:convert';

import 'package:corehealth_flutter/src/data/remote_app_repository.dart';
import 'package:corehealth_flutter/src/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'corehealth_jwt': 'test-token',
    });
  });

  test('bootstrap hydrates BE aiPlans into the mobile plan cache', () async {
    final repository = RemoteAppRepository(
      baseUrl: 'https://api.test/api',
      client: MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/me/bootstrap'));
        return http.Response(
          jsonEncode({
            'session': {
              'userId': 'user-1',
              'email': 'demo@corehealth.app',
              'status': 'active',
            },
            'userData': _userDataJson(
              aiPlans: {
                'mealPlan': [_mealPlanDay(1).toJson()],
                'workoutPlan': [_workoutDay(1).toJson()],
              },
            ),
          }),
          200,
        );
      }),
    );

    await repository.init();
    final bootstrap = await repository.bootstrap();

    expect(bootstrap.session?.userId, equals('user-1'));
    expect(await repository.getCurrentGeneration(userId: 'user-1'), isNotNull);
    expect(
      (await repository.getMealPlan(userId: 'user-1', version: 1, dayIndex: 1))
          ?.meals
          .single
          .nameVi,
      equals('Meal 1'),
    );
    expect(
      (await repository.getWorkoutPlan(
              userId: 'user-1', version: 1, dayIndex: 1))
          ?.exercises
          .single
          .nameVi,
      equals('Workout 1'),
    );
  });

  test('saving final plan day syncs aiPlans to the shared backend', () async {
    final requests = <http.Request>[];
    final repository = RemoteAppRepository(
      baseUrl: 'https://api.test/api',
      client: MockClient((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], equals('Bearer test-token'));
        if (request.url.path == '/api/me/ai-plans') {
          return http.Response(jsonEncode(_userDataJson()), 200);
        }
        return http.Response('{}', 404);
      }),
    );

    await repository.init();
    await repository.saveMealPlan(
      userId: 'user-1',
      generationId: 'gen-1',
      dayIndex: 30,
      plan: _mealPlanDay(30),
    );

    final syncRequest = requests.singleWhere(
      (request) => request.url.path == '/api/me/ai-plans',
    );
    final payload = jsonDecode(syncRequest.body) as Map<String, dynamic>;
    expect(payload['mealPlan'], isA<List<dynamic>>());
    expect((payload['mealPlan'] as List).single['dayNumber'], equals(30));
  });

  test('creates a shop payment order on the shared backend', () async {
    late Map<String, dynamic> payload;
    final repository = RemoteAppRepository(
      baseUrl: 'https://api.test/api',
      client: MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/payments/create-order'));
        expect(request.headers['Authorization'], equals('Bearer test-token'));
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'orderId': 'ord-1',
            'reference': 'CH12061234',
            'qrUrl': 'https://qr.example/CH12061234',
            'bankName': 'MB Bank',
            'accountNumber': '123456',
            'accountOwner': 'COREHEALTH',
            'expiresAt': '2026-06-12T10:00:00Z',
            'amountVnd': 25000,
          }),
          200,
        );
      }),
    );

    await repository.init();
    final order = await repository.createShopPaymentOrder(
      userId: 'user-1',
      items: [
        const Product(
          id: 'protein-bar',
          nameVi: 'Protein Bar',
          categoryId: 'snack',
          unit: 'piece',
          priceK: 25,
          imageUrl: '',
          hot: false,
        ),
      ],
      deliveryName: 'Demo User',
      deliveryPhone: '0900000000',
      deliveryAddress: 'Ho Chi Minh City',
    );

    expect(order.reference, equals('CH12061234'));
    expect(order.amountVnd, equals(25000));
    expect((payload['items'] as List).single,
        equals({'id': 'protein-bar', 'qty': 1}));
    expect(payload['deliveryName'], equals('Demo User'));
  });

  test('creates a token top-up order on the shared backend', () async {
    final repository = RemoteAppRepository(
      baseUrl: 'https://api.test/api',
      client: MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.path,
          equals('/api/billing/token-packs/starter/sepay'),
        );
        expect(request.headers['Authorization'], equals('Bearer test-token'));
        return http.Response(
          jsonEncode({
            'id': 'topup-1',
            'packId': 'starter',
            'reference': 'CH12069999',
            'amountVnd': 49000,
            'tokenAmount': 55,
            'qrUrl': 'https://qr.example/CH12069999',
            'bankName': 'MB Bank',
            'accountNumber': '123456',
            'accountOwner': 'COREHEALTH',
            'expiresAt': '2026-06-12T10:00:00Z',
          }),
          200,
        );
      }),
    );

    await repository.init();
    final order = await repository.createTokenTopupOrder(
      userId: 'user-1',
      pack: tokenPacks.first,
    );

    expect(order.orderId, equals('topup-1'));
    expect(order.reference, equals('CH12069999'));
    expect(order.amountVnd, equals(49000));
    expect(order.packId, equals('starter'));
    expect(order.tokenAmount, equals(55));
  });
}

Map<String, dynamic> _userDataJson({Map<String, dynamic>? aiPlans}) => {
      'profile': {
        'name': 'Demo User',
        'age': 28,
        'gender': 'other',
        'heightCm': 168,
        'weightKg': 65,
        'targetWeightKg': 62,
        'goal': 'maintain',
        'activityLevel': 'moderate',
        'plan': 'free',
        'subscriptionMonths': 0,
        'tokenBalance': 100,
        'aiPlanVersion': 1,
      },
      'weightHistory': [],
      'completedWorkoutDays': [],
      'completedMealDays': [],
      'cart': [],
      'orders': [],
      'settings': {},
      if (aiPlans != null) 'aiPlans': aiPlans,
    };

MealPlanDay _mealPlanDay(int dayNumber) => MealPlanDay(
      dayNumber: dayNumber,
      meals: [
        MealItem(
          id: 'meal-$dayNumber',
          nameVi: 'Meal $dayNumber',
          slotLabel: 'Sang',
          calories: 400,
          protein: 25,
          carbs: 45,
          fat: 12,
          imageUrl: '',
          ingredients: const ['Rice'],
        ),
      ],
    );

WorkoutDay _workoutDay(int dayNumber) => WorkoutDay(
      dayNumber: dayNumber,
      focusVi: 'Workout focus $dayNumber',
      exercises: [
        WorkoutExercise(
          id: 'workout-$dayNumber',
          nameVi: 'Workout $dayNumber',
          description: '',
          sets: 3,
          reps: '10',
          caloriesBurned: 120,
        ),
      ],
    );
