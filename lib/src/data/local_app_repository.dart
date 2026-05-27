import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../demo_data.dart';
import '../models.dart';

abstract class AppRepository {
  Future<AppBootstrapData> bootstrap();
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });
  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
  });
  Future<AuthResult> signInWithGoogle({required String idToken});
  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  });
  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  });
  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  });
  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  });
  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  });
  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  });
  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  });
  Future<PersistedUserData> clearCart({
    required String userId,
  });
  Future<PersistedUserData> placeOrder({
    required String userId,
  });
  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  });
  Future<void> signOut();
  Future<void> insertMealLog({required String userId, required MealLog log});
  Future<List<MealLog>> getMealLogsForDate(
      {required String userId, required String date});
  Future<void> deleteMealLog({required String userId, required String logId});
}

class AppBootstrapData {
  const AppBootstrapData({
    this.session,
    this.userData,
  });

  final AppUserSession? session;
  final PersistedUserData? userData;
}

class AuthResult {
  const AuthResult({
    required this.session,
    required this.userData,
  });

  final AppUserSession session;
  final PersistedUserData userData;
}

class PersistedUserData {
  const PersistedUserData({
    required this.profile,
    required this.weightHistory,
    required this.completedWorkoutDays,
    required this.completedMealDays,
    required this.cart,
    required this.orders,
  });

  final DemoProfile profile;
  final List<WeightEntry> weightHistory;
  final Set<int> completedWorkoutDays;
  final Set<int> completedMealDays;
  final List<Product> cart;
  final List<OrderSummary> orders;
}

class AppAuthException implements Exception {
  const AppAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalAppRepository implements AppRepository {
  LocalAppRepository({DatabaseFactory? databaseFactory})
      : _databaseFactory =
            databaseFactory ?? (kIsWeb ? null : _defaultDatabaseFactory());

  final DatabaseFactory? _databaseFactory;
  final _memoryStore = _MemoryStore();
  Database? _database;

  @override
  Future<AppBootstrapData> bootstrap() async {
    if (kIsWeb) {
      return _memoryStore.bootstrap();
    }

    final database = await _openDatabase();
    final sessionRows = await database.query(_sessionsTable, limit: 1);
    if (sessionRows.isEmpty) {
      return const AppBootstrapData();
    }

    final userId = sessionRows.first['user_id'] as String?;
    if (userId == null || userId.isEmpty) {
      await database.delete(_sessionsTable);
      return const AppBootstrapData();
    }

    final account = await _readUserAccount(database, userId);
    if (account == null) {
      await database.delete(_sessionsTable);
      return const AppBootstrapData();
    }

    final userData = await _readUserData(database, userId);
    final profileRow = await _readProfileRow(database, userId);

    return AppBootstrapData(
      session: AppUserSession(
        userId: userId,
        email: account.email,
        onboardingCompleted: _isOnboardingCompleted(profileRow),
      ),
      userData: userData,
    );
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (kIsWeb) {
      return _memoryStore.signIn(email: email, password: password);
    }

    final normalizedEmail = _normalizeEmail(email);
    final database = await _openDatabase();
    final rows = await database.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    final row = rows.first;
    final storedSalt = row['password_salt'] as String? ?? '';
    final expectedHash = storedSalt.isEmpty
        ? _hashPasswordLegacy(password)
        : _hashPasswordWithSalt(password, storedSalt);
    if ((row['password_hash'] as String? ?? '') != expectedHash) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    final userId = row['id'] as String;
    await _persistSession(database, userId);
    final profileRow = await _readProfileRow(database, userId);

    return AuthResult(
      session: AppUserSession(
        userId: userId,
        email: normalizedEmail,
        onboardingCompleted: _isOnboardingCompleted(profileRow),
      ),
      userData: await _readUserData(database, userId),
    );
  }

  @override
  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (kIsWeb) {
      return _memoryStore.register(
        displayName: displayName,
        email: email,
        password: password,
      );
    }

    final normalizedName = displayName.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedName.isEmpty) {
      throw const AppAuthException('Tên hiển thị không được để trống.');
    }

    final database = await _openDatabase();
    final existing = await database.query(
      _usersTable,
      columns: const ['id'],
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const AppAuthException('Email này đã được đăng ký.');
    }

    final userId = _generateUserId();
    final now = DateTime.now().toIso8601String();
    final salt = _generateSalt();

    await database.transaction((txn) async {
      await txn.insert(
        _usersTable,
        {
          'id': userId,
          'email': normalizedEmail,
          'password_hash': _hashPasswordWithSalt(password, salt),
          'password_salt': salt,
          'display_name': normalizedName,
          'created_at': now,
        },
      );
      await _insertDefaultProfile(txn,
          userId: userId, displayName: normalizedName);
      await _persistSession(txn, userId);
    });

    return AuthResult(
      session: AppUserSession(
        userId: userId,
        email: normalizedEmail,
        onboardingCompleted: false,
      ),
      userData: await _readUserData(database, userId),
    );
  }

  @override
  Future<AuthResult> signInWithGoogle({required String idToken}) async {
    throw const AppAuthException(
      'Đăng nhập bằng Google yêu cầu kết nối tới máy chủ CoreHealth.',
    );
  }

  @override
  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  }) async {
    if (kIsWeb) {
      return _memoryStore.saveOnboardingProfile(
          userId: userId, profile: profile);
    }

    final database = await _openDatabase();
    await database.transaction((txn) async {
      await _upsertProfile(
        txn,
        userId: userId,
        profile: profile,
        onboardingCompleted: true,
      );
      await txn.delete(
        _weightEntriesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final entry in _seedWeightHistory(profile)) {
        await txn.insert(
          _weightEntriesTable,
          {
            'user_id': userId,
            'label': entry.label,
            'weight': entry.weight,
            'recorded_at': _recordedAtFromLabel(entry.label),
          },
        );
      }
    });

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  }) async {
    if (kIsWeb) {
      return _memoryStore.updateSubscription(
        userId: userId,
        plan: plan,
        months: months,
      );
    }

    final database = await _openDatabase();
    final currentProfile = await _readProfile(database, userId);
    final updatedProfile = currentProfile.copyWith(
      plan: plan,
      subscriptionMonths: months,
      // Only stamp a start date when activating a paid plan.
      // When downgrading to free, explicitly clear it.
      subscriptionStartDate:
          plan == SubscriptionPlan.free ? null : DateTime.now(),
    );
    await _upsertProfile(
      database,
      userId: userId,
      profile: updatedProfile,
      onboardingCompleted: true,
    );

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  }) async {
    if (kIsWeb) {
      return _memoryStore.updateWeight(userId: userId, weight: weight);
    }

    final database = await _openDatabase();
    final currentProfile = await _readProfile(database, userId);
    final updatedProfile = currentProfile.copyWith(weightKg: weight);

    await database.transaction((txn) async {
      await _upsertProfile(
        txn,
        userId: userId,
        profile: updatedProfile,
        onboardingCompleted: true,
      );
      await txn.insert(
        _weightEntriesTable,
        {
          'user_id': userId,
          'label': _formatDayMonth(DateTime.now()),
          'weight': weight,
          'recorded_at': DateTime.now().toIso8601String(),
        },
      );

      final rows = await txn.query(
        _weightEntriesTable,
        columns: const ['id'],
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'recorded_at DESC, id DESC',
      );
      final idsToDelete = rows.skip(8).map((row) => row['id']).toList();
      if (idsToDelete.isNotEmpty) {
        await txn.delete(
          _weightEntriesTable,
          where: 'id IN (${List.filled(idsToDelete.length, '?').join(', ')})',
          whereArgs: idsToDelete,
        );
      }
    });

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    if (kIsWeb) {
      return _memoryStore.toggleWorkoutCompleted(
        userId: userId,
        dayNumber: dayNumber,
      );
    }

    final database = await _openDatabase();
    final existing = await database.query(
      _workoutCompletionsTable,
      columns: const ['day_number'],
      where: 'user_id = ? AND day_number = ?',
      whereArgs: [userId, dayNumber],
      limit: 1,
    );

    if (existing.isEmpty) {
      await database.insert(
        _workoutCompletionsTable,
        {
          'user_id': userId,
          'day_number': dayNumber,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
    } else {
      await database.delete(
        _workoutCompletionsTable,
        where: 'user_id = ? AND day_number = ?',
        whereArgs: [userId, dayNumber],
      );
    }

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    if (kIsWeb) {
      return _memoryStore.toggleMealCompleted(
        userId: userId,
        dayNumber: dayNumber,
      );
    }

    final database = await _openDatabase();
    final existing = await database.query(
      _mealCompletionsTable,
      columns: const ['day_number'],
      where: 'user_id = ? AND day_number = ?',
      whereArgs: [userId, dayNumber],
      limit: 1,
    );

    if (existing.isEmpty) {
      await database.insert(
        _mealCompletionsTable,
        {
          'user_id': userId,
          'day_number': dayNumber,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
    } else {
      await database.delete(
        _mealCompletionsTable,
        where: 'user_id = ? AND day_number = ?',
        whereArgs: [userId, dayNumber],
      );
    }

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  }) async {
    if (kIsWeb) {
      return _memoryStore.addToCart(userId: userId, product: product);
    }

    final database = await _openDatabase();
    // Prevent adding the same product twice.
    final existing = await database.query(
      _cartItemsTable,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, product.id],
      limit: 1,
    );
    if (existing.isNotEmpty) return _readUserData(database, userId);

    await database.insert(
      _cartItemsTable,
      {
        'user_id': userId,
        'product_id': product.id,
        'added_at': DateTime.now().toIso8601String(),
      },
    );

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    if (kIsWeb) {
      return _memoryStore.removeCartItem(userId: userId, productId: productId);
    }

    final database = await _openDatabase();
    await database.delete(
      _cartItemsTable,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> clearCart({
    required String userId,
  }) async {
    if (kIsWeb) {
      return _memoryStore.clearCart(userId: userId);
    }

    final database = await _openDatabase();
    await database.delete(
      _cartItemsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> placeOrder({
    required String userId,
  }) async {
    if (kIsWeb) {
      return _memoryStore.placeOrder(userId: userId);
    }

    final database = await _openDatabase();
    final cart = await _readCart(database, userId);
    if (cart.isEmpty) {
      return _readUserData(database, userId);
    }

    final now = DateTime.now();
    await database.transaction((txn) async {
      await txn.insert(
        _ordersTable,
        {
          'id': 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}',
          'user_id': userId,
          'date_label': _formatDate(now),
          'item_count': cart.length,
          'total_k': cart.fold<int>(0, (sum, item) => sum + item.priceK),
          'status_label': 'Đang xử lý',
          'created_at': now.toIso8601String(),
        },
      );
      await txn.delete(
        _cartItemsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });

    return _readUserData(database, userId);
  }

  @override
  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  }) async {
    if (kIsWeb) {
      return _memoryStore.placeOrderItems(
          userId: userId, productIds: productIds);
    }

    if (productIds.isEmpty) {
      final database = await _openDatabase();
      return _readUserData(database, userId);
    }

    final database = await _openDatabase();
    final cart = await _readCart(database, userId);
    final selected =
        cart.where((product) => productIds.contains(product.id)).toList();
    if (selected.isEmpty) {
      return _readUserData(database, userId);
    }

    final now = DateTime.now();
    final placeholders = List.filled(productIds.length, '?').join(', ');
    await database.transaction((txn) async {
      await txn.insert(
        _ordersTable,
        {
          'id': 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}',
          'user_id': userId,
          'date_label': _formatDate(now),
          'item_count': selected.length,
          'total_k': selected.fold<int>(0, (sum, item) => sum + item.priceK),
          'status_label': 'Đang xử lý',
          'created_at': now.toIso8601String(),
        },
      );
      await txn.delete(
        _cartItemsTable,
        where: 'user_id = ? AND product_id IN ($placeholders)',
        whereArgs: [userId, ...productIds],
      );
    });

    return _readUserData(database, userId);
  }

  @override
  Future<void> insertMealLog(
      {required String userId, required MealLog log}) async {
    if (kIsWeb) {
      _memoryStore.insertMealLog(userId: userId, log: log);
      return;
    }
    final db = await _openDatabase();
    await db.insert(
        _mealLogsTable,
        {
          'id': log.id,
          'user_id': userId,
          'date': log.dateKey,
          'slot_label': log.slotLabel,
          'food_name': log.foodName,
          'calories': log.calories,
          'protein': log.protein,
          'carbs': log.carbs,
          'fat': log.fat,
          'logged_at': log.loggedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<MealLog>> getMealLogsForDate(
      {required String userId, required String date}) async {
    if (kIsWeb) {
      return _memoryStore.getMealLogsForDate(userId: userId, date: date);
    }
    final db = await _openDatabase();
    final rows = await db.query(_mealLogsTable,
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
        orderBy: 'logged_at ASC');
    return rows.map(_mealLogFromRow).toList();
  }

  @override
  Future<void> deleteMealLog(
      {required String userId, required String logId}) async {
    if (kIsWeb) {
      _memoryStore.deleteMealLog(userId: userId, logId: logId);
      return;
    }
    final db = await _openDatabase();
    await db.delete(_mealLogsTable,
        where: 'id = ? AND user_id = ?', whereArgs: [logId, userId]);
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb) {
      await _memoryStore.signOut();
      return;
    }

    final database = await _openDatabase();
    await database.delete(_sessionsTable);
  }

  Future<Database> _openDatabase() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final databaseFactory = _databaseFactory;
    if (databaseFactory == null) {
      throw StateError('Database factory is unavailable for this platform.');
    }

    final databasePath = p.join(
      await databaseFactory.getDatabasesPath(),
      'corehealth.db',
    );

    final database = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 9,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, _) => _createSchema(db),
        onUpgrade: _migrateSchema,
      ),
    );

    _database = database;
    return database;
  }

  Future<void> _migrateSchema(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute(
          "ALTER TABLE $_profilesTable ADD COLUMN allergies_json TEXT NOT NULL DEFAULT '[]'",
        );
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE $_profilesTable ADD COLUMN subscription_start_date TEXT',
        );
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_mealLogsTable (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            date TEXT NOT NULL,
            slot_label TEXT NOT NULL,
            food_name TEXT NOT NULL,
            calories INTEGER NOT NULL,
            protein REAL NOT NULL,
            carbs REAL NOT NULL,
            fat REAL NOT NULL,
            logged_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_mealCompletionsTable (
            user_id TEXT NOT NULL,
            day_number INTEGER NOT NULL,
            completed_at TEXT NOT NULL,
            PRIMARY KEY (user_id, day_number),
            FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          "ALTER TABLE $_usersTable ADD COLUMN password_salt TEXT NOT NULL DEFAULT ''",
        );
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }
    if (oldVersion < 8) {
      for (final statement in [
        "ALTER TABLE $_profilesTable ADD COLUMN training_frequency TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE $_profilesTable ADD COLUMN focus_areas_json TEXT NOT NULL DEFAULT '[]'",
        "ALTER TABLE $_profilesTable ADD COLUMN preferred_activities_json TEXT NOT NULL DEFAULT '[]'",
        "ALTER TABLE $_profilesTable ADD COLUMN meal_budget TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE $_profilesTable ADD COLUMN cooking_time TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE $_profilesTable ADD COLUMN nutrition_priorities_json TEXT NOT NULL DEFAULT '[]'",
      ]) {
        try {
          await db.execute(statement);
        } catch (e) {
          debugPrint('Migration warning: $e');
        }
      }
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
          'ALTER TABLE $_profilesTable ADD COLUMN core_health_max_trial_expires_at TEXT',
        );
      } catch (e) {
        debugPrint('Migration warning: $e');
      }
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_usersTable (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL DEFAULT '',
        display_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_sessionsTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_profilesTable (
        user_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        target_weight_kg REAL NOT NULL,
        goal TEXT NOT NULL,
        activity_level TEXT NOT NULL,
        schedule TEXT NOT NULL,
        dietary_restrictions_json TEXT NOT NULL,
        allergies_json TEXT NOT NULL DEFAULT '[]',
        health_conditions_json TEXT NOT NULL,
        training_frequency TEXT NOT NULL DEFAULT '',
        focus_areas_json TEXT NOT NULL DEFAULT '[]',
        preferred_activities_json TEXT NOT NULL DEFAULT '[]',
        meal_budget TEXT NOT NULL DEFAULT '',
        cooking_time TEXT NOT NULL DEFAULT '',
        nutrition_priorities_json TEXT NOT NULL DEFAULT '[]',
        subscription_start_date TEXT,
        core_health_max_trial_expires_at TEXT,
        plan TEXT NOT NULL,
        subscription_months INTEGER NOT NULL,
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_weightEntriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        label TEXT NOT NULL,
        weight REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_workoutCompletionsTable (
        user_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        PRIMARY KEY (user_id, day_number),
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_mealCompletionsTable (
        user_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        PRIMARY KEY (user_id, day_number),
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_cartItemsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_ordersTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date_label TEXT NOT NULL,
        item_count INTEGER NOT NULL,
        total_k INTEGER NOT NULL,
        status_label TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_mealLogsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        slot_label TEXT NOT NULL,
        food_name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        logged_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _persistSession(DatabaseExecutor executor, String userId) async {
    await executor.insert(
      _sessionsTable,
      {
        'id': 1,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _insertDefaultProfile(
    DatabaseExecutor executor, {
    required String userId,
    required String displayName,
  }) async {
    final profile = _defaultProfileFor(displayName);
    await _upsertProfile(
      executor,
      userId: userId,
      profile: profile,
      onboardingCompleted: false,
    );

    for (final entry in _seedWeightHistory(profile).take(3)) {
      await executor.insert(
        _weightEntriesTable,
        {
          'user_id': userId,
          'label': entry.label,
          'weight': entry.weight,
          'recorded_at': _recordedAtFromLabel(entry.label),
        },
      );
    }
  }

  Future<void> _upsertProfile(
    DatabaseExecutor executor, {
    required String userId,
    required DemoProfile profile,
    required bool onboardingCompleted,
  }) async {
    await executor.insert(
      _profilesTable,
      {
        'user_id': userId,
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender.name,
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'target_weight_kg': profile.targetWeightKg,
        'goal': profile.goal.name,
        'activity_level': profile.activityLevel.name,
        'schedule': profile.schedule,
        'dietary_restrictions_json': jsonEncode(profile.dietaryRestrictions),
        'allergies_json': jsonEncode(profile.allergies),
        'health_conditions_json': jsonEncode(profile.healthConditions),
        'training_frequency': profile.trainingFrequency,
        'focus_areas_json': jsonEncode(profile.focusAreas),
        'preferred_activities_json': jsonEncode(profile.preferredActivities),
        'meal_budget': profile.mealBudget,
        'cooking_time': profile.cookingTime,
        'nutrition_priorities_json': jsonEncode(profile.nutritionPriorities),
        'subscription_start_date':
            profile.subscriptionStartDate?.toIso8601String(),
        'core_health_max_trial_expires_at':
            profile.coreHealthMaxTrialExpiresAt?.toIso8601String(),
        'plan': profile.plan.name,
        'subscription_months': profile.subscriptionMonths,
        'onboarding_completed': onboardingCompleted ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<_UserAccount?> _readUserAccount(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return _UserAccount(
      id: rows.first['id'] as String,
      email: rows.first['email'] as String,
      displayName: rows.first['display_name'] as String,
    );
  }

  Future<Map<String, Object?>> _readProfileRow(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _profilesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      final account = await _readUserAccount(executor, userId);
      final fallback = _defaultProfileFor(
          account?.displayName ?? DemoData.initialProfile.name);
      await _upsertProfile(
        executor,
        userId: userId,
        profile: fallback,
        onboardingCompleted: false,
      );
      return (await executor.query(
        _profilesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      ))
          .first;
    }

    return rows.first;
  }

  Future<DemoProfile> _readProfile(
    DatabaseExecutor executor,
    String userId,
  ) async {
    return _profileFromRow(await _readProfileRow(executor, userId));
  }

  Future<PersistedUserData> _readUserData(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final profile = await _readProfile(executor, userId);
    return PersistedUserData(
      profile: profile,
      weightHistory:
          await _readWeightHistory(executor, userId, fallback: profile),
      completedWorkoutDays: await _readWorkoutDays(executor, userId),
      completedMealDays: await _readMealDays(executor, userId),
      cart: await _readCart(executor, userId),
      orders: await _readOrders(executor, userId),
    );
  }

  Future<List<WeightEntry>> _readWeightHistory(
    DatabaseExecutor executor,
    String userId, {
    required DemoProfile fallback,
  }) async {
    final rows = await executor.query(
      _weightEntriesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'recorded_at ASC, id ASC',
    );
    if (rows.isEmpty) {
      return _seedWeightHistory(fallback).take(3).toList(growable: false);
    }

    return rows
        .map(
          (row) => WeightEntry(
            label: row['label'] as String,
            weight: (row['weight'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  Future<Set<int>> _readWorkoutDays(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _workoutCompletionsTable,
      columns: const ['day_number'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((row) => row['day_number'] as int).toSet();
  }

  Future<Set<int>> _readMealDays(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _mealCompletionsTable,
      columns: const ['day_number'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((row) => row['day_number'] as int).toSet();
  }

  Future<List<Product>> _readCart(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _cartItemsTable,
      columns: const ['product_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
    return rows
        .map((row) => _productById[row['product_id'] as String])
        .whereType<Product>()
        .toList(growable: false);
  }

  Future<List<OrderSummary>> _readOrders(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _ordersTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (row) => OrderSummary(
            id: row['id'] as String,
            dateLabel: row['date_label'] as String,
            itemCount: row['item_count'] as int,
            totalK: row['total_k'] as int,
            statusLabel: row['status_label'] as String,
          ),
        )
        .toList(growable: false);
  }

  bool _isOnboardingCompleted(Map<String, Object?> row) {
    return (row['onboarding_completed'] as int? ?? 0) == 1;
  }
}

class _UserAccount {
  const _UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;
}

class _MemoryStore {
  final Map<String, _MemoryUserRecord> _usersById = {};
  final Map<String, String> _userIdByEmail = {};
  final Map<String, PersistedUserData> _dataByUserId = {};
  // userId → list of logs
  final Map<String, List<MealLog>> _mealLogsByUser = {};
  String? _currentUserId;

  void insertMealLog({required String userId, required MealLog log}) {
    final logs = _mealLogsByUser.putIfAbsent(userId, () => []);
    logs.removeWhere((l) => l.id == log.id);
    logs.add(log);
  }

  List<MealLog> getMealLogsForDate(
      {required String userId, required String date}) {
    return (_mealLogsByUser[userId] ?? [])
        .where((l) => l.dateKey == date)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  void deleteMealLog({required String userId, required String logId}) {
    _mealLogsByUser[userId]?.removeWhere((l) => l.id == logId);
  }

  Future<AppBootstrapData> bootstrap() async {
    final userId = _currentUserId;
    if (userId == null) {
      return const AppBootstrapData();
    }

    final record = _usersById[userId];
    final data = _dataByUserId[userId];
    if (record == null || data == null) {
      _currentUserId = null;
      return const AppBootstrapData();
    }

    return AppBootstrapData(
      session: AppUserSession(
        userId: record.id,
        email: record.email,
        onboardingCompleted: record.onboardingCompleted,
      ),
      userData: data,
    );
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final userId = _userIdByEmail[normalizedEmail];
    if (userId == null) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    final record = _usersById[userId];
    if (record == null ||
        record.passwordHash !=
            _hashPasswordWithSalt(password, record.passwordSalt)) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    _currentUserId = userId;
    return AuthResult(
      session: AppUserSession(
        userId: record.id,
        email: record.email,
        onboardingCompleted: record.onboardingCompleted,
      ),
      userData: _dataByUserId[userId]!,
    );
  }

  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final normalizedName = displayName.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (_userIdByEmail.containsKey(normalizedEmail)) {
      throw const AppAuthException('Email này đã được đăng ký.');
    }

    final userId = _generateUserId();
    final profile = _defaultProfileFor(normalizedName);
    final salt = _generateSalt();
    final record = _MemoryUserRecord(
      id: userId,
      email: normalizedEmail,
      passwordHash: _hashPasswordWithSalt(password, salt),
      passwordSalt: salt,
      displayName: normalizedName,
      onboardingCompleted: false,
    );
    _usersById[userId] = record;
    _userIdByEmail[normalizedEmail] = userId;
    _currentUserId = userId;
    _dataByUserId[userId] = PersistedUserData(
      profile: profile,
      weightHistory:
          _seedWeightHistory(profile).take(3).toList(growable: false),
      completedWorkoutDays: const {},
      completedMealDays: const {},
      cart: const [],
      orders: const [],
    );

    return AuthResult(
      session: AppUserSession(
        userId: record.id,
        email: record.email,
        onboardingCompleted: false,
      ),
      userData: _dataByUserId[userId]!,
    );
  }

  Future<PersistedUserData> saveOnboardingProfile({
    required String userId,
    required DemoProfile profile,
  }) async {
    final record = _usersById[userId];
    if (record != null) {
      _usersById[userId] = record.copyWith(onboardingCompleted: true);
    }

    final updated = PersistedUserData(
      profile: profile,
      weightHistory: _seedWeightHistory(profile),
      completedWorkoutDays: const {},
      completedMealDays: const {},
      cart: _dataByUserId[userId]?.cart ?? const [],
      orders: _dataByUserId[userId]?.orders ?? const [],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> updateSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required int months,
  }) async {
    final current = _requireUserData(userId);
    final updated = PersistedUserData(
      profile: current.profile.copyWith(
        plan: plan,
        subscriptionMonths: months,
        subscriptionStartDate:
            plan == SubscriptionPlan.free ? null : DateTime.now(),
      ),
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: current.cart,
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> updateWeight({
    required String userId,
    required double weight,
  }) async {
    final current = _requireUserData(userId);
    final updatedHistory = [
      ...current.weightHistory,
      WeightEntry(label: _formatDayMonth(DateTime.now()), weight: weight),
    ];
    while (updatedHistory.length > 8) {
      updatedHistory.removeAt(0);
    }

    final updated = PersistedUserData(
      profile: current.profile.copyWith(weightKg: weight),
      weightHistory: updatedHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: current.cart,
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> toggleWorkoutCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final current = _requireUserData(userId);
    final completedDays = {...current.completedWorkoutDays};
    if (!completedDays.add(dayNumber)) {
      completedDays.remove(dayNumber);
    }

    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: completedDays,
      completedMealDays: current.completedMealDays,
      cart: current.cart,
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> toggleMealCompleted({
    required String userId,
    required int dayNumber,
  }) async {
    final current = _requireUserData(userId);
    final completedDays = {...current.completedMealDays};
    if (!completedDays.add(dayNumber)) {
      completedDays.remove(dayNumber);
    }

    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: completedDays,
      cart: current.cart,
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> addToCart({
    required String userId,
    required Product product,
  }) async {
    final current = _requireUserData(userId);
    // Prevent adding the same product twice.
    if (current.cart.any((p) => p.id == product.id)) return current;
    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: [...current.cart, product],
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    final current = _requireUserData(userId);
    final cart = current.cart.where((p) => p.id != productId).toList();
    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: cart,
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> clearCart({
    required String userId,
  }) async {
    final current = _requireUserData(userId);
    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: const [],
      orders: current.orders,
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> placeOrder({
    required String userId,
  }) async {
    final current = _requireUserData(userId);
    if (current.cart.isEmpty) {
      return current;
    }

    final now = DateTime.now();
    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: const [],
      orders: [
        OrderSummary(
          id: 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}',
          dateLabel: _formatDate(now),
          itemCount: current.cart.length,
          totalK: current.cart.fold<int>(0, (sum, item) => sum + item.priceK),
          statusLabel: 'Đang xử lý',
        ),
        ...current.orders,
      ],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<PersistedUserData> placeOrderItems({
    required String userId,
    required Set<String> productIds,
  }) async {
    final current = _requireUserData(userId);
    if (productIds.isEmpty) {
      return current;
    }

    final selected = current.cart
        .where((product) => productIds.contains(product.id))
        .toList();
    if (selected.isEmpty) {
      return current;
    }

    final now = DateTime.now();
    final updated = PersistedUserData(
      profile: current.profile,
      weightHistory: current.weightHistory,
      completedWorkoutDays: current.completedWorkoutDays,
      completedMealDays: current.completedMealDays,
      cart: current.cart
          .where((product) => !productIds.contains(product.id))
          .toList(growable: false),
      orders: [
        OrderSummary(
          id: 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}',
          dateLabel: _formatDate(now),
          itemCount: selected.length,
          totalK: selected.fold<int>(0, (sum, item) => sum + item.priceK),
          statusLabel: 'Đang xử lý',
        ),
        ...current.orders,
      ],
    );
    _dataByUserId[userId] = updated;
    return updated;
  }

  Future<void> signOut() async {
    _currentUserId = null;
  }

  PersistedUserData _requireUserData(String userId) {
    final data = _dataByUserId[userId];
    if (data == null) {
      throw StateError('User data not found for $userId');
    }
    return data;
  }
}

class _MemoryUserRecord {
  const _MemoryUserRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.displayName,
    required this.onboardingCompleted,
  });

  final String id;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String displayName;
  final bool onboardingCompleted;

  _MemoryUserRecord copyWith({
    bool? onboardingCompleted,
  }) {
    return _MemoryUserRecord(
      id: id,
      email: email,
      passwordHash: passwordHash,
      passwordSalt: passwordSalt,
      displayName: displayName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

DemoProfile _defaultProfileFor(String displayName) {
  return DemoData.initialProfile.copyWith(
    name: displayName,
    plan: SubscriptionPlan.free,
    subscriptionMonths: 1,
  );
}

DemoProfile _profileFromRow(Map<String, Object?> row) {
  return DemoProfile(
    name: row['name'] as String? ?? DemoData.initialProfile.name,
    age: row['age'] as int? ?? DemoData.initialProfile.age,
    gender: _enumByName(
      Gender.values,
      row['gender'] as String?,
      fallback: DemoData.initialProfile.gender,
    ),
    heightCm: (row['height_cm'] as num?)?.toDouble() ??
        DemoData.initialProfile.heightCm,
    weightKg: (row['weight_kg'] as num?)?.toDouble() ??
        DemoData.initialProfile.weightKg,
    targetWeightKg: (row['target_weight_kg'] as num?)?.toDouble() ??
        DemoData.initialProfile.targetWeightKg,
    goal: _enumByName(
      GoalType.values,
      row['goal'] as String?,
      fallback: DemoData.initialProfile.goal,
    ),
    activityLevel: _enumByName(
      ActivityLevel.values,
      row['activity_level'] as String?,
      fallback: DemoData.initialProfile.activityLevel,
    ),
    schedule: row['schedule'] as String? ?? DemoData.initialProfile.schedule,
    dietaryRestrictions:
        _decodeStringList(row['dietary_restrictions_json'] as String?),
    allergies: _decodeStringList(row['allergies_json'] as String?),
    healthConditions:
        _decodeStringList(row['health_conditions_json'] as String?),
    trainingFrequency: row['training_frequency'] as String? ?? '',
    focusAreas: _decodeStringList(row['focus_areas_json'] as String?),
    preferredActivities:
        _decodeStringList(row['preferred_activities_json'] as String?),
    mealBudget: row['meal_budget'] as String? ?? '',
    cookingTime: row['cooking_time'] as String? ?? '',
    nutritionPriorities:
        _decodeStringList(row['nutrition_priorities_json'] as String?),
    subscriptionStartDate: row['subscription_start_date'] == null
        ? null
        : DateTime.tryParse(row['subscription_start_date'] as String),
    coreHealthMaxTrialExpiresAt: row['core_health_max_trial_expires_at'] == null
        ? null
        : DateTime.tryParse(
            row['core_health_max_trial_expires_at'] as String,
          ),
    plan: _enumByName(
      SubscriptionPlan.values,
      row['plan'] as String?,
      fallback: DemoData.initialProfile.plan,
    ),
    subscriptionMonths: row['subscription_months'] as int? ??
        DemoData.initialProfile.subscriptionMonths,
  );
}

List<WeightEntry> _seedWeightHistory(DemoProfile profile) {
  final current = profile.weightKg;
  final values = [
    current + 2.1,
    current + 1.7,
    current + 1.2,
    current + 0.8,
    current + 0.4,
    current + 0.2,
    current,
  ];
  final today = DateTime.now();

  return List.generate(values.length, (index) {
    final date = today.subtract(Duration(days: values.length - index - 1));
    return WeightEntry(
      label: _formatDayMonth(date),
      weight: double.parse(values[index].toStringAsFixed(1)),
    );
  });
}

T _enumByName<T extends Enum>(
  List<T> values,
  String? raw, {
  required T fallback,
}) {
  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }

  return fallback;
}

List<String> _decodeStringList(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const [];
  }

  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => item.toString()).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

String _formatDayMonth(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _formatDate(DateTime value) {
  return '${_formatDayMonth(value)}/${value.year}';
}

String _recordedAtFromLabel(String label) {
  final segments = label.split('/');
  if (segments.length != 2) {
    return DateTime.now().toIso8601String();
  }

  final day = int.tryParse(segments[0]);
  final month = int.tryParse(segments[1]);
  if (day == null || month == null) {
    return DateTime.now().toIso8601String();
  }

  final now = DateTime.now();
  return DateTime(now.year, month, day).toIso8601String();
}

String _normalizeEmail(String value) => value.trim().toLowerCase();

// Legacy static salt — used only for verifying passwords created before per-user salt migration.
const _kPasswordSalt = 'CHv1_2026_s@lt';

String _hashPasswordLegacy(String value) =>
    sha256.convert(utf8.encode('$_kPasswordSalt:$value')).toString();

String _hashPasswordWithSalt(String value, String salt) =>
    sha256.convert(utf8.encode('$salt:$value')).toString();

String _generateSalt() {
  final random = Random.secure();
  return List<int>.generate(8, (_) => random.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

String _generateUserId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return 'usr_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

DatabaseFactory _defaultDatabaseFactory() {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  return databaseFactory;
}

const _usersTable = 'users';
const _sessionsTable = 'sessions';
const _profilesTable = 'user_profiles';
const _weightEntriesTable = 'weight_entries';
const _workoutCompletionsTable = 'workout_completions';
const _mealCompletionsTable = 'meal_completions';
const _cartItemsTable = 'cart_items';
const _ordersTable = 'orders';
const _mealLogsTable = 'meal_logs';

MealLog _mealLogFromRow(Map<String, Object?> row) => MealLog(
      id: row['id'] as String,
      slotLabel: row['slot_label'] as String,
      foodName: row['food_name'] as String,
      calories: row['calories'] as int,
      protein: (row['protein'] as num).toDouble(),
      carbs: (row['carbs'] as num).toDouble(),
      fat: (row['fat'] as num).toDouble(),
      loggedAt: DateTime.parse(row['logged_at'] as String),
    );

final Map<String, Product> _productById = {
  for (final product in DemoData.products) product.id: product,
};
