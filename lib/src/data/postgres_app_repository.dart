import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../demo_data.dart';
import '../models.dart';
import '../services/email_service.dart';
import 'app_repository.dart';

class PostgresAppRepository implements AppRepository {
  PostgresAppRepository({
    required String host,
    required String database,
    required String username,
    required String password,
    int port = 5432,
  })  : _host = host,
        _databaseName = database,
        _username = username,
        _password = password,
        _port = port;

  final String _host;
  final String _databaseName;
  final String _username;
  final String _password;
  final int _port;

  Connection? _connection;

  Future<void> init() async {
    await _open();
    await _ensureSchema();
  }

  Future<Connection> _open() async {
    final existing = _connection;
    if (existing != null) return existing;
    final conn = await Connection.open(
      Endpoint(
        host: _host,
        port: _port,
        database: _databaseName,
        username: _username,
        password: _password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    _connection = conn;
    return conn;
  }

  Future<void> _ensureSchema() async {
    final db = await _open();
    for (final statement in _schemaStatements) {
      await db.execute(statement);
    }
  }

  @override
  Future<AppBootstrapData> bootstrap() async {
    final db = await _open();
    final sessions =
        await db.execute('select user_id from sessions where id = 1 limit 1');
    if (sessions.isEmpty) return const AppBootstrapData();
    final userId = sessions.first.toColumnMap()['user_id']?.toString() ?? '';
    if (userId.isEmpty) return const AppBootstrapData();
    final account = await _readUserAccount(db, userId);
    if (account == null) {
      await db.execute('delete from sessions where id = 1');
      return const AppBootstrapData();
    }
    final profileRow = await _readProfileRow(db, userId);
    return AppBootstrapData(
      session: AppUserSession(
        userId: userId,
        email: account.email,
        onboardingCompleted: _isOnboardingCompleted(profileRow),
      ),
      userData: await _readUserData(db, userId),
    );
  }

  @override
  Future<AuthResult> signIn(
      {required String email, required String password}) async {
    final db = await _open();
    final normalizedEmail = _normalizeEmail(email);
    final rows = await db.execute(
      Sql.named('select * from users where email = @email limit 1'),
      parameters: {'email': normalizedEmail},
    );
    if (rows.isEmpty) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    final row = rows.first.toColumnMap();
    final salt = row['password_salt']?.toString() ?? '';
    final expectedHash = salt.isEmpty
        ? _hashPasswordLegacy(password)
        : _hashPasswordWithSalt(password, salt);
    if ((row['password_hash']?.toString() ?? '') != expectedHash) {
      throw const AppAuthException('Email hoặc mật khẩu không đúng.');
    }

    final userId = row['id'].toString();
    await _persistSession(db, userId);
    final profileRow = await _readProfileRow(db, userId);
    return AuthResult(
      session: AppUserSession(
        userId: userId,
        email: normalizedEmail,
        onboardingCompleted: _isOnboardingCompleted(profileRow),
      ),
      userData: await _readUserData(db, userId),
    );
  }

  @override
  Future<RegisterResponseData> register({
    required String displayName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final db = await _open();
    final normalizedName = displayName.trim();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedName.isEmpty) {
      throw const AppAuthException('Tên hiển thị không được để trống.');
    }
    if (await _emailExists(db, normalizedEmail)) {
      throw const AppAuthException('Email này đã được đăng ký.');
    }

    if (referralCode != null && referralCode.trim().isNotEmpty) {
      final refRows = await db.execute(
        Sql.named(
            'select user_id from user_profiles where upper(referral_code) = @code limit 1'),
        parameters: {'code': referralCode.trim().toUpperCase()},
      );
      if (refRows.isEmpty) {
        throw const AppAuthException('Mã giới thiệu không hợp lệ.');
      }
    }

    final otp = _generateOtp();
    final salt = _generateSalt();
    await db.execute(
      Sql.named('''
        insert into pending_verify (
          email, display_name, password_hash, password_salt, otp_code, referral_code, expires_at, failed_attempts, updated_at
        ) values (
          @email, @displayName, @passwordHash, @passwordSalt, @otp, @referralCode, @expiresAt, 0, now()
        )
        on conflict (email) do update set
          display_name = excluded.display_name,
          password_hash = excluded.password_hash,
          password_salt = excluded.password_salt,
          otp_code = excluded.otp_code,
          referral_code = excluded.referral_code,
          expires_at = excluded.expires_at,
          failed_attempts = 0,
          updated_at = now()
      '''),
      parameters: {
        'email': normalizedEmail,
        'displayName': normalizedName,
        'passwordHash': _hashPasswordWithSalt(password, salt),
        'passwordSalt': salt,
        'otp': otp,
        'referralCode': referralCode?.trim(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
      },
    );

    await EmailService().sendOtpEmail(toEmail: normalizedEmail, otp: otp);
    return RegisterResponseData(
        success: true, email: normalizedEmail, devOtp: otp);
  }

  @override
  Future<AuthResult> verifyOtp(
      {required String email, required String otp}) async {
    final db = await _open();
    final normalizedEmail = _normalizeEmail(email);
    late String userId;

    await db.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('select * from pending_verify where email = @email limit 1'),
        parameters: {'email': normalizedEmail},
      );
      if (rows.isEmpty) {
        throw const AppAuthException(
            'Không tìm thấy thông tin đăng ký cho email này. Vui lòng đăng ký lại.');
      }

      final pending = rows.first.toColumnMap();
      final expiresAt = _parseDate(pending['expires_at']);
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
        await tx.execute(
            Sql.named('delete from pending_verify where email = @email'),
            parameters: {'email': normalizedEmail});
        throw const AppAuthException(
            'Mã xác thực đã hết hạn. Vui lòng đăng ký lại.');
      }

      if ((pending['otp_code']?.toString() ?? '') != otp.trim()) {
        final failed = _intValue(pending['failed_attempts']) + 1;
        if (failed >= 5) {
          await tx.execute(
              Sql.named('delete from pending_verify where email = @email'),
              parameters: {'email': normalizedEmail});
        } else {
          await tx.execute(
            Sql.named(
                'update pending_verify set failed_attempts = @failed where email = @email'),
            parameters: {'failed': failed, 'email': normalizedEmail},
          );
        }
        throw const AppAuthException('Mã xác thực không chính xác.');
      }

      if (await _emailExists(tx, normalizedEmail)) {
        throw const AppAuthException('Email này đã được đăng ký.');
      }

      userId = _generateUserId();
      final displayName = pending['display_name'].toString();
      await tx.execute(
        Sql.named('''
          insert into users (id, email, password_hash, password_salt, display_name, created_at, updated_at)
          values (@id, @email, @passwordHash, @passwordSalt, @displayName, now(), now())
        '''),
        parameters: {
          'id': userId,
          'email': normalizedEmail,
          'passwordHash': pending['password_hash'].toString(),
          'passwordSalt': pending['password_salt'].toString(),
          'displayName': displayName,
        },
      );

      final profile = await _profileForNewVerifiedUser(
          tx, userId, displayName, pending['referral_code']?.toString());
      await _upsertProfile(tx,
          userId: userId, profile: profile, onboardingCompleted: false);
      await tx.execute(
        Sql.named('''
          insert into token_transactions(id, user_id, amount, price_k, description, created_at)
          values (@id, @userId, @amount, @priceK, @description, now())
        '''),
        parameters: {
          'id': 'txn_${DateTime.now().microsecondsSinceEpoch}_signup',
          'userId': userId,
          'amount': 25,
          'priceK': 0,
          'description': 'Quà tặng đăng ký mới',
        },
      );
      if (pending['referral_code']?.toString().trim().isNotEmpty == true) {
        await tx.execute(
          Sql.named('''
            insert into token_transactions(id, user_id, amount, price_k, description, created_at)
            values (@id, @userId, @amount, @priceK, @description, now())
          '''),
          parameters: {
            'id': 'txn_${DateTime.now().microsecondsSinceEpoch}_ref_bonus_new',
            'userId': userId,
            'amount': 40,
            'priceK': 0,
            'description': 'Quà tặng đăng ký qua mã giới thiệu',
          },
        );
      }
      await _persistSession(tx, userId);
      await tx.execute(
          Sql.named('delete from pending_verify where email = @email'),
          parameters: {'email': normalizedEmail});
    });

    return AuthResult(
      session: AppUserSession(
          userId: userId, email: normalizedEmail, onboardingCompleted: false),
      userData: await _readUserData(db, userId),
    );
  }

  @override
  Future<RegisterResponseData> resendOtp({required String email}) async {
    final db = await _open();
    final normalizedEmail = _normalizeEmail(email);
    final rows = await db.execute(
      Sql.named('select * from pending_verify where email = @email limit 1'),
      parameters: {'email': normalizedEmail},
    );
    if (rows.isEmpty) {
      throw const AppAuthException(
          'Không tìm thấy thông tin đăng ký cho email này. Vui lòng đăng ký lại.');
    }

    final pending = rows.first.toColumnMap();
    final updatedAt = _parseDate(pending['updated_at']);
    if (updatedAt != null &&
        DateTime.now().difference(updatedAt).inSeconds < 60) {
      throw const AppAuthException(
          'Vui lòng đợi 60 giây trước khi yêu cầu gửi lại mã.');
    }

    final otp = _generateOtp();
    await db.execute(
      Sql.named('''
        update pending_verify
        set otp_code = @otp, expires_at = @expiresAt, failed_attempts = 0, updated_at = now()
        where email = @email
      '''),
      parameters: {
        'otp': otp,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
        'email': normalizedEmail,
      },
    );
    await EmailService().sendOtpEmail(toEmail: normalizedEmail, otp: otp);
    return RegisterResponseData(
        success: true, email: normalizedEmail, devOtp: otp);
  }

  @override
  Future<RegisterResponseData> requestPasswordReset({
    required String email,
  }) async {
    final db = await _open();
    final normalizedEmail = _normalizeEmail(email);
    final userRows = await db.execute(
      Sql.named('select id from users where email = @email limit 1'),
      parameters: {'email': normalizedEmail},
    );
    if (userRows.isEmpty) {
      return RegisterResponseData(success: true, email: normalizedEmail);
    }

    final otp = _generateOtp();
    await db.execute(
      Sql.named('''
        insert into password_resets (email, otp_code, expires_at, failed_attempts, updated_at)
        values (@email, @otp, @expiresAt, 0, now())
        on conflict (email) do update set
          otp_code = excluded.otp_code,
          expires_at = excluded.expires_at,
          failed_attempts = 0,
          updated_at = now()
      '''),
      parameters: {
        'email': normalizedEmail,
        'otp': otp,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
      },
    );
    await EmailService().sendPasswordResetEmail(
      toEmail: normalizedEmail,
      otp: otp,
    );
    return RegisterResponseData(
        success: true, email: normalizedEmail, devOtp: otp);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final db = await _open();
    final normalizedEmail = _normalizeEmail(email);
    await db.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('select * from password_resets where email = @email limit 1'),
        parameters: {'email': normalizedEmail},
      );
      if (rows.isEmpty) {
        throw const AppAuthException(
            'Mã đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.');
      }
      final reset = rows.first.toColumnMap();
      final expiresAt = _parseDate(reset['expires_at']);
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        await tx.execute(
          Sql.named('delete from password_resets where email = @email'),
          parameters: {'email': normalizedEmail},
        );
        throw const AppAuthException(
            'Mã đặt lại mật khẩu đã hết hạn. Vui lòng gửi lại mã.');
      }

      if ((reset['otp_code']?.toString() ?? '') != otp.trim()) {
        final failed = _intValue(reset['failed_attempts']) + 1;
        if (failed >= 5) {
          await tx.execute(
            Sql.named('delete from password_resets where email = @email'),
            parameters: {'email': normalizedEmail},
          );
        } else {
          await tx.execute(
            Sql.named(
                'update password_resets set failed_attempts = @failed where email = @email'),
            parameters: {'email': normalizedEmail, 'failed': failed},
          );
        }
        throw const AppAuthException('Mã OTP không chính xác.');
      }

      final salt = _generateSalt();
      await tx.execute(
        Sql.named('''
          update users
          set password_hash = @passwordHash, password_salt = @passwordSalt, updated_at = now()
          where email = @email
        '''),
        parameters: {
          'email': normalizedEmail,
          'passwordHash': _hashPasswordWithSalt(newPassword, salt),
          'passwordSalt': salt,
        },
      );
      await tx.execute(
        Sql.named('delete from password_resets where email = @email'),
        parameters: {'email': normalizedEmail},
      );
    });
  }

  @override
  Future<AuthResult> signInWithGoogle({required String idToken}) async {
    throw const AppAuthException(
        'Đăng nhập bằng Google chưa hỗ trợ ở chế độ PostgreSQL local.');
  }

  @override
  Future<PersistedUserData> saveOnboardingProfile(
      {required String userId, required DemoProfile profile}) async {
    final db = await _open();
    await db.runTx((tx) async {
      await _upsertProfile(tx,
          userId: userId, profile: profile, onboardingCompleted: true);
      await _replaceWeightHistory(tx, userId, _seedWeightHistory(profile));
    });
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> updateSubscription(
      {required String userId,
      required SubscriptionPlan plan,
      required int months}) async {
    final db = await _open();
    final current = await _readProfile(db, userId);
    await _upsertProfile(
      db,
      userId: userId,
      profile: current.copyWith(
        plan: plan,
        subscriptionMonths: months,
        subscriptionStartDate:
            plan == SubscriptionPlan.free ? null : DateTime.now(),
      ),
      onboardingCompleted: true,
    );
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> updateTokenWallet({
    required String userId,
    required int tokenBalance,
    required int tokenEarned,
    required int tokenSpent,
  }) async {
    final db = await _open();
    final current = await _readProfile(db, userId);
    await _upsertProfile(
      db,
      userId: userId,
      profile: current.copyWith(
          tokenBalance: tokenBalance,
          tokenEarned: tokenEarned,
          tokenSpent: tokenSpent),
      onboardingCompleted: true,
    );
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> updateUserSettings({
    required String userId,
    required UserSettings settings,
  }) async {
    final db = await _open();
    await _upsertSettings(db, userId: userId, settings: settings);
    return _readUserData(db, userId);
  }

  @override
  Future<List<TokenTransaction>> getTokenTransactions({
    required String userId,
  }) async {
    final db = await _open();
    final rows = await db.execute(
      Sql.named(
        'select * from token_transactions where user_id = @userId order by created_at desc',
      ),
      parameters: {'userId': userId},
    );
    return rows
        .map((row) => _tokenTransactionFromMap(row.toColumnMap()))
        .toList(growable: false);
  }

  @override
  Future<void> addTokenTransaction({
    required String userId,
    required TokenTransaction transaction,
  }) async {
    final db = await _open();
    await db.execute(
      Sql.named('''
        insert into token_transactions(id, user_id, amount, price_k, description, created_at)
        values (@id, @userId, @amount, @priceK, @description, @createdAt)
        on conflict (id) do update set
          amount = excluded.amount,
          price_k = excluded.price_k,
          description = excluded.description,
          created_at = excluded.created_at
      '''),
      parameters: {
        'id': transaction.id,
        'userId': userId,
        'amount': transaction.amount,
        'priceK': transaction.priceK,
        'description': transaction.description,
        'createdAt': transaction.createdAt,
      },
    );
  }

  @override
  Future<PersistedUserData> updateWeight(
      {required String userId, required double weight}) async {
    final db = await _open();
    final current = await _readProfile(db, userId);
    await db.runTx((tx) async {
      await _upsertProfile(tx,
          userId: userId,
          profile: current.copyWith(weightKg: weight),
          onboardingCompleted: true);
      await tx.execute(
        Sql.named(
            'insert into weight_entries(user_id, label, weight, recorded_at) values (@userId, @label, @weight, now())'),
        parameters: {
          'userId': userId,
          'label': _formatDayMonth(DateTime.now()),
          'weight': weight
        },
      );
      await tx.execute(
        Sql.named('''
          delete from weight_entries
          where id in (
            select id from weight_entries where user_id = @userId order by recorded_at desc, id desc offset 8
          )
        '''),
        parameters: {'userId': userId},
      );
    });
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> toggleWorkoutCompleted(
      {required String userId, required int dayNumber}) {
    return _toggleDay('workout_completions', userId, dayNumber);
  }

  @override
  Future<PersistedUserData> toggleMealCompleted(
      {required String userId, required int dayNumber}) {
    return _toggleDay('meal_completions', userId, dayNumber);
  }

  Future<PersistedUserData> _toggleDay(
      String table, String userId, int dayNumber) async {
    final db = await _open();
    final existing = await db.execute(
      Sql.named(
          'select day_number from $table where user_id = @userId and day_number = @dayNumber limit 1'),
      parameters: {'userId': userId, 'dayNumber': dayNumber},
    );
    if (existing.isEmpty) {
      await db.execute(
        Sql.named(
            'insert into $table(user_id, day_number, completed_at) values (@userId, @dayNumber, now())'),
        parameters: {'userId': userId, 'dayNumber': dayNumber},
      );
    } else {
      await db.execute(
        Sql.named(
            'delete from $table where user_id = @userId and day_number = @dayNumber'),
        parameters: {'userId': userId, 'dayNumber': dayNumber},
      );
    }
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> addToCart(
      {required String userId, required Product product}) async {
    final db = await _open();
    await db.execute(
      Sql.named('''
        insert into cart_items(user_id, product_id, added_at)
        values (@userId, @productId, now())
        on conflict (user_id, product_id) do nothing
      '''),
      parameters: {'userId': userId, 'productId': product.id},
    );
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> removeCartItem(
      {required String userId, required String productId}) async {
    final db = await _open();
    await db.execute(
      Sql.named(
          'delete from cart_items where user_id = @userId and product_id = @productId'),
      parameters: {'userId': userId, 'productId': productId},
    );
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> clearCart({required String userId}) async {
    final db = await _open();
    await db.execute(
        Sql.named('delete from cart_items where user_id = @userId'),
        parameters: {'userId': userId});
    return _readUserData(db, userId);
  }

  @override
  Future<PersistedUserData> placeOrder({required String userId}) async {
    final db = await _open();
    final cart = await _readCart(db, userId);
    if (cart.isEmpty) return _readUserData(db, userId);
    return _placeOrderForProducts(
        db, userId, cart, cart.map((item) => item.id).toSet());
  }

  @override
  Future<PersistedUserData> placeOrderItems(
      {required String userId, required Set<String> productIds}) async {
    final db = await _open();
    if (productIds.isEmpty) return _readUserData(db, userId);
    final cart = await _readCart(db, userId);
    final selected = cart
        .where((item) => productIds.contains(item.id))
        .toList(growable: false);
    if (selected.isEmpty) return _readUserData(db, userId);
    return _placeOrderForProducts(db, userId, selected, productIds);
  }

  Future<PersistedUserData> _placeOrderForProducts(Connection db, String userId,
      List<Product> products, Set<String> productIds) async {
    final now = DateTime.now();
    final orderId = 'ODR-${now.microsecondsSinceEpoch.toString().substring(9)}';
    await db.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          insert into orders(id, user_id, date_label, item_count, total_k, status_label, created_at)
          values (@id, @userId, @dateLabel, @itemCount, @totalK, @statusLabel, @createdAt)
        '''),
        parameters: {
          'id': orderId,
          'userId': userId,
          'dateLabel': _formatDate(now),
          'itemCount': products.length,
          'totalK': products.fold<int>(0, (sum, item) => sum + item.priceK),
          'statusLabel': 'Đang xử lý',
          'createdAt': now,
        },
      );
      for (final productId in productIds) {
        await tx.execute(
          Sql.named(
              'delete from cart_items where user_id = @userId and product_id = @productId'),
          parameters: {'userId': userId, 'productId': productId},
        );
      }
    });
    return _readUserData(db, userId);
  }

  @override
  Future<void> signOut() async {
    final db = await _open();
    await db.execute('delete from sessions');
  }

  @override
  Future<void> insertMealLog(
      {required String userId, required MealLog log}) async {
    final db = await _open();
    await db.execute(
      Sql.named('''
        insert into meal_logs(id, user_id, date, slot_label, food_name, calories, protein, carbs, fat, logged_at)
        values (@id, @userId, @date, @slotLabel, @foodName, @calories, @protein, @carbs, @fat, @loggedAt)
        on conflict (id) do update set
          slot_label = excluded.slot_label,
          food_name = excluded.food_name,
          calories = excluded.calories,
          protein = excluded.protein,
          carbs = excluded.carbs,
          fat = excluded.fat,
          logged_at = excluded.logged_at
      '''),
      parameters: {
        'id': log.id,
        'userId': userId,
        'date': log.dateKey,
        'slotLabel': log.slotLabel,
        'foodName': log.foodName,
        'calories': log.calories,
        'protein': log.protein,
        'carbs': log.carbs,
        'fat': log.fat,
        'loggedAt': log.loggedAt,
      },
    );
  }

  @override
  Future<List<MealLog>> getMealLogsForDate(
      {required String userId, required String date}) async {
    final db = await _open();
    final rows = await db.execute(
      Sql.named(
          'select * from meal_logs where user_id = @userId and date = @date order by logged_at asc'),
      parameters: {'userId': userId, 'date': date},
    );
    return rows
        .map((row) => _mealLogFromMap(row.toColumnMap()))
        .toList(growable: false);
  }

  @override
  Future<void> deleteMealLog(
      {required String userId, required String logId}) async {
    final db = await _open();
    await db.execute(
      Sql.named('delete from meal_logs where user_id = @userId and id = @id'),
      parameters: {'userId': userId, 'id': logId},
    );
  }

  @override
  Future<List<ChatSession>> getChatSessions({required String userId}) async {
    final db = await _open();
    final rows = await db.execute(
      Sql.named(
          'select id, title, ts, history_json, category from chat_sessions where user_id = @userId order by ts desc'),
      parameters: {'userId': userId},
    );
    return rows.map((row) {
      final colMap = row.toColumnMap();
      final list = jsonDecode(colMap['history_json'] as String) as List? ?? [];
      final historyList = list.map((item) {
        final map = item as Map<String, dynamic>;
        return ChatMessage(
          text: map['text'] as String? ?? '',
          isUser: map['isUser'] as bool? ?? false,
        );
      }).toList();
      return ChatSession(
        id: colMap['id'] as String? ?? '',
        title: colMap['title'] as String? ?? 'Cuộc trò chuyện mới',
        ts: (colMap['ts'] as num? ?? DateTime.now().millisecondsSinceEpoch)
            .toInt(),
        history: historyList,
        category: colMap['category'] as String? ?? 'General',
      );
    }).toList();
  }

  @override
  Future<void> saveChatSession(
      {required String userId, required ChatSession session}) async {
    final db = await _open();
    final historyJson = jsonEncode(session.history
        .map((m) => {'text': m.text, 'isUser': m.isUser})
        .toList());
    await db.execute(
      Sql.named('''
        insert into chat_sessions (id, user_id, title, ts, history_json, category)
        values (@id, @userId, @title, @ts, @historyJson, @category)
        on conflict (id) do update set
          title = excluded.title,
          ts = excluded.ts,
          history_json = excluded.history_json,
          category = excluded.category
      '''),
      parameters: {
        'id': session.id,
        'userId': userId,
        'title': session.title,
        'ts': session.ts,
        'historyJson': historyJson,
        'category': session.category,
      },
    );
  }

  @override
  Future<void> deleteChatSession(
      {required String userId, required String sessionId}) async {
    final db = await _open();
    await db.execute(
      Sql.named(
          'delete from chat_sessions where user_id = @userId and id = @sessionId'),
      parameters: {
        'userId': userId,
        'sessionId': sessionId,
      },
    );
  }

  Future<_UserAccount?> _readUserAccount(dynamic db, String userId) async {
    final rows = await db.execute(
        Sql.named('select * from users where id = @id limit 1'),
        parameters: {'id': userId});
    if (rows.isEmpty) return null;
    final row = rows.first.toColumnMap();
    return _UserAccount(
        id: row['id'].toString(),
        email: row['email'].toString(),
        displayName: row['display_name'].toString());
  }

  Future<Map<String, dynamic>> _readProfileRow(
      dynamic db, String userId) async {
    final rows = await db.execute(
        Sql.named(
            'select * from user_profiles where user_id = @userId limit 1'),
        parameters: {'userId': userId});
    if (rows.isEmpty) {
      final account = await _readUserAccount(db, userId);
      final profile = _defaultProfileFor(
          account?.displayName ?? DemoData.initialProfile.name);
      await _upsertProfile(db,
          userId: userId, profile: profile, onboardingCompleted: false);
      return _readProfileRow(db, userId);
    }
    return rows.first.toColumnMap();
  }

  Future<DemoProfile> _readProfile(dynamic db, String userId) async {
    return _profileFromMap(await _readProfileRow(db, userId));
  }

  Future<PersistedUserData> _readUserData(dynamic db, String userId) async {
    final profile = await _readProfile(db, userId);
    return PersistedUserData(
      profile: profile,
      weightHistory: await _readWeightHistory(db, userId, fallback: profile),
      completedWorkoutDays: await _readDays(db, 'workout_completions', userId),
      completedMealDays: await _readDays(db, 'meal_completions', userId),
      cart: await _readCart(db, userId),
      orders: await _readOrders(db, userId),
      settings: await _readSettings(db, userId),
    );
  }

  Future<UserSettings> _readSettings(dynamic db, String userId) async {
    final rows = await db.execute(
      Sql.named('select * from user_settings where user_id = @userId limit 1'),
      parameters: {'userId': userId},
    ) as Result;
    if (rows.isEmpty) return const UserSettings();
    return _settingsFromMap(rows.first.toColumnMap());
  }

  Future<List<WeightEntry>> _readWeightHistory(dynamic db, String userId,
      {required DemoProfile fallback}) async {
    final rows = await db.execute(
      Sql.named(
          'select label, weight from weight_entries where user_id = @userId order by recorded_at asc, id asc'),
      parameters: {'userId': userId},
    ) as Result;
    if (rows.isEmpty) {
      return _seedWeightHistory(fallback).take(3).toList(growable: false);
    }
    return rows.map((row) {
      final map = row.toColumnMap();
      return WeightEntry(
          label: map['label'].toString(), weight: _doubleValue(map['weight']));
    }).toList(growable: false);
  }

  Future<Set<int>> _readDays(dynamic db, String table, String userId) async {
    final rows = await db.execute(
      Sql.named('select day_number from $table where user_id = @userId'),
      parameters: {'userId': userId},
    ) as Result;
    return rows
        .map((row) => _intValue(row.toColumnMap()['day_number']))
        .toSet();
  }

  Future<List<Product>> _readCart(dynamic db, String userId) async {
    final rows = await db.execute(
      Sql.named(
          'select product_id from cart_items where user_id = @userId order by id asc'),
      parameters: {'userId': userId},
    ) as Result;
    return rows
        .map((row) => _productById[row.toColumnMap()['product_id'].toString()])
        .whereType<Product>()
        .toList(growable: false);
  }

  Future<List<OrderSummary>> _readOrders(dynamic db, String userId) async {
    final rows = await db.execute(
      Sql.named(
          'select * from orders where user_id = @userId order by created_at desc'),
      parameters: {'userId': userId},
    ) as Result;
    return rows.map((row) {
      final map = row.toColumnMap();
      return OrderSummary(
        id: map['id'].toString(),
        dateLabel: map['date_label'].toString(),
        itemCount: _intValue(map['item_count']),
        totalK: _intValue(map['total_k']),
        statusLabel: map['status_label'].toString(),
      );
    }).toList(growable: false);
  }

  Future<void> _persistSession(dynamic db, String userId) async {
    await db.execute(
      Sql.named('''
        insert into sessions(id, user_id, created_at)
        values (1, @userId, now())
        on conflict (id) do update set user_id = excluded.user_id, created_at = now()
      '''),
      parameters: {'userId': userId},
    );
  }

  Future<void> _upsertSettings(
    dynamic db, {
    required String userId,
    required UserSettings settings,
  }) async {
    await db.execute(
      Sql.named('''
        insert into user_settings (
          user_id, water_reminder_enabled, workout_reminder_enabled,
          weekly_weight_reminder_enabled, language, updated_at
        ) values (
          @userId, @waterReminderEnabled, @workoutReminderEnabled,
          @weeklyWeightReminderEnabled, @language, now()
        )
        on conflict (user_id) do update set
          water_reminder_enabled = excluded.water_reminder_enabled,
          workout_reminder_enabled = excluded.workout_reminder_enabled,
          weekly_weight_reminder_enabled = excluded.weekly_weight_reminder_enabled,
          language = excluded.language,
          updated_at = now()
      '''),
      parameters: {
        'userId': userId,
        'waterReminderEnabled': settings.waterReminderEnabled,
        'workoutReminderEnabled': settings.workoutReminderEnabled,
        'weeklyWeightReminderEnabled': settings.weeklyWeightReminderEnabled,
        'language': settings.language,
      },
    );
  }

  Future<void> _upsertProfile(dynamic db,
      {required String userId,
      required DemoProfile profile,
      required bool onboardingCompleted}) async {
    await db.execute(
      Sql.named('''
        insert into user_profiles (
          user_id, name, age, gender, height_cm, weight_kg, target_weight_kg, goal, activity_level, schedule,
          dietary_restrictions_json, allergies_json, health_conditions_json, training_frequency, focus_areas_json,
          preferred_activities_json, meal_budget, cooking_time, nutrition_priorities_json, subscription_start_date,
          core_health_max_trial_expires_at, plan, subscription_months, token_balance, token_earned, token_spent,
          referral_code, referred_by, onboarding_completed, updated_at
        ) values (
          @userId, @name, @age, @gender, @heightCm, @weightKg, @targetWeightKg, @goal, @activityLevel, @schedule,
          @dietaryRestrictionsJson, @allergiesJson, @healthConditionsJson, @trainingFrequency, @focusAreasJson,
          @preferredActivitiesJson, @mealBudget, @cookingTime, @nutritionPrioritiesJson, @subscriptionStartDate,
          @coreHealthMaxTrialExpiresAt, @plan, @subscriptionMonths, @tokenBalance, @tokenEarned, @tokenSpent,
          @referralCode, @referredBy, @onboardingCompleted, now()
        )
        on conflict (user_id) do update set
          name = excluded.name,
          age = excluded.age,
          gender = excluded.gender,
          height_cm = excluded.height_cm,
          weight_kg = excluded.weight_kg,
          target_weight_kg = excluded.target_weight_kg,
          goal = excluded.goal,
          activity_level = excluded.activity_level,
          schedule = excluded.schedule,
          dietary_restrictions_json = excluded.dietary_restrictions_json,
          allergies_json = excluded.allergies_json,
          health_conditions_json = excluded.health_conditions_json,
          training_frequency = excluded.training_frequency,
          focus_areas_json = excluded.focus_areas_json,
          preferred_activities_json = excluded.preferred_activities_json,
          meal_budget = excluded.meal_budget,
          cooking_time = excluded.cooking_time,
          nutrition_priorities_json = excluded.nutrition_priorities_json,
          subscription_start_date = excluded.subscription_start_date,
          core_health_max_trial_expires_at = excluded.core_health_max_trial_expires_at,
          plan = excluded.plan,
          subscription_months = excluded.subscription_months,
          token_balance = excluded.token_balance,
          token_earned = excluded.token_earned,
          token_spent = excluded.token_spent,
          referral_code = excluded.referral_code,
          referred_by = excluded.referred_by,
          onboarding_completed = excluded.onboarding_completed,
          updated_at = now()
      '''),
      parameters: _profileParameters(userId, profile, onboardingCompleted),
    );
  }

  Map<String, Object?> _profileParameters(
          String userId, DemoProfile profile, bool onboardingCompleted) =>
      {
        'userId': userId,
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender.name,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'targetWeightKg': profile.targetWeightKg,
        'goal': profile.goal.name,
        'activityLevel': profile.activityLevel.name,
        'schedule': profile.schedule,
        'dietaryRestrictionsJson': jsonEncode(profile.dietaryRestrictions),
        'allergiesJson': jsonEncode(profile.allergies),
        'healthConditionsJson': jsonEncode(profile.healthConditions),
        'trainingFrequency': profile.trainingFrequency,
        'focusAreasJson': jsonEncode(profile.focusAreas),
        'preferredActivitiesJson': jsonEncode(profile.preferredActivities),
        'mealBudget': profile.mealBudget,
        'cookingTime': profile.cookingTime,
        'nutritionPrioritiesJson': jsonEncode(profile.nutritionPriorities),
        'subscriptionStartDate': profile.subscriptionStartDate,
        'coreHealthMaxTrialExpiresAt': profile.coreHealthMaxTrialExpiresAt,
        'plan': profile.plan.name,
        'subscriptionMonths': profile.subscriptionMonths,
        'tokenBalance': profile.tokenBalance,
        'tokenEarned': profile.tokenEarned,
        'tokenSpent': profile.tokenSpent,
        'referralCode': profile.referralCode,
        'referredBy': profile.referredBy,
        'onboardingCompleted': onboardingCompleted,
      };

  Future<bool> _emailExists(dynamic db, String email) async {
    final rows = await db.execute(
        Sql.named('select 1 from users where email = @email limit 1'),
        parameters: {'email': email});
    return rows.isNotEmpty;
  }

  Future<DemoProfile> _profileForNewVerifiedUser(dynamic db, String userId,
      String displayName, String? referralCode) async {
    final myReferralCode = _generateReferralCode(displayName);
    var signupTokens = 25;
    var referrerId = '';
    if (referralCode != null && referralCode.trim().isNotEmpty) {
      final refRows = await db.execute(
        Sql.named(
            'select user_id from user_profiles where upper(referral_code) = @code limit 1'),
        parameters: {'code': referralCode.trim().toUpperCase()},
      );
      if (refRows.isEmpty) {
        throw const AppAuthException('Mã giới thiệu không hợp lệ.');
      }
      referrerId = refRows.first.toColumnMap()['user_id'].toString();
      if (referrerId == userId) {
        throw const AppAuthException(
            'Không thể tự dùng mã giới thiệu của chính mình.');
      }
      signupTokens = 65;

      final countRows = await db.execute(
        Sql.named(
            'select count(*) as count from user_profiles where referred_by = @referrerId'),
        parameters: {'referrerId': referrerId},
      );
      final nextCount = _intValue(countRows.first.toColumnMap()['count']) + 1;
      if (nextCount > 0 && nextCount % 5 == 0) {
        await db.execute(
          Sql.named('''
            update user_profiles
            set token_balance = token_balance + 20, token_earned = token_earned + 20, updated_at = now()
            where user_id = @referrerId
          '''),
          parameters: {'referrerId': referrerId},
        );
        await db.execute(
          Sql.named('''
            insert into token_transactions(id, user_id, amount, price_k, description, created_at)
            values (@id, @userId, @amount, @priceK, @description, now())
          '''),
          parameters: {
            'id': 'txn_${DateTime.now().microsecondsSinceEpoch}_ref_bonus',
            'userId': referrerId,
            'amount': 20,
            'priceK': 0,
            'description': 'Thưởng mốc giới thiệu bạn bè',
          },
        );
      }
    }

    // Return a blank profile for the database to avoid saving default choices
    // before the user completes onboarding.
    return DemoProfile(
      name: displayName,
      age: 0,
      gender: Gender.other,
      heightCm: 0,
      weightKg: 0,
      targetWeightKg: 0,
      goal: GoalType.maintain,
      activityLevel: ActivityLevel.sedentary,
      schedule: '',
      dietaryRestrictions: const [],
      allergies: const [],
      healthConditions: const [],
      trainingFrequency: '',
      focusAreas: const [],
      preferredActivities: const [],
      mealBudget: '',
      cookingTime: '',
      nutritionPriorities: const [],
      plan: SubscriptionPlan.free,
      subscriptionMonths: 0,
      tokenBalance: signupTokens,
      tokenEarned: signupTokens,
      tokenSpent: 0,
      referralCode: myReferralCode,
      referredBy: referrerId,
    );
  }

  Future<void> _replaceWeightHistory(
      dynamic db, String userId, List<WeightEntry> entries) async {
    await db.execute(
        Sql.named('delete from weight_entries where user_id = @userId'),
        parameters: {'userId': userId});
    for (final entry in entries) {
      await db.execute(
        Sql.named(
            'insert into weight_entries(user_id, label, weight, recorded_at) values (@userId, @label, @weight, @recordedAt)'),
        parameters: {
          'userId': userId,
          'label': entry.label,
          'weight': entry.weight,
          'recordedAt': _recordedAtFromLabel(entry.label)
        },
      );
    }
  }
}

class _UserAccount {
  const _UserAccount(
      {required this.id, required this.email, required this.displayName});

  final String id;
  final String email;
  final String displayName;
}

DemoProfile _profileFromMap(Map<String, Object?> row) {
  return DemoProfile(
    name: row['name'] as String? ?? DemoData.initialProfile.name,
    age: _intValue(row['age'], fallback: DemoData.initialProfile.age),
    gender: _enumByName(Gender.values, row['gender'] as String?,
        fallback: DemoData.initialProfile.gender),
    heightCm: _doubleValue(row['height_cm'],
        fallback: DemoData.initialProfile.heightCm),
    weightKg: _doubleValue(row['weight_kg'],
        fallback: DemoData.initialProfile.weightKg),
    targetWeightKg: _doubleValue(row['target_weight_kg'],
        fallback: DemoData.initialProfile.targetWeightKg),
    goal: _enumByName(GoalType.values, row['goal'] as String?,
        fallback: DemoData.initialProfile.goal),
    activityLevel: _enumByName(
        ActivityLevel.values, row['activity_level'] as String?,
        fallback: DemoData.initialProfile.activityLevel),
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
    subscriptionStartDate: _parseDate(row['subscription_start_date']),
    coreHealthMaxTrialExpiresAt:
        _parseDate(row['core_health_max_trial_expires_at']),
    plan: _enumByName(SubscriptionPlan.values, row['plan'] as String?,
        fallback: DemoData.initialProfile.plan),
    subscriptionMonths: _intValue(row['subscription_months'],
        fallback: DemoData.initialProfile.subscriptionMonths),
    tokenBalance: _intValue(row['token_balance'],
        fallback: DemoData.initialProfile.tokenBalance),
    tokenEarned: _intValue(row['token_earned'],
        fallback: DemoData.initialProfile.tokenEarned),
    tokenSpent: _intValue(row['token_spent'],
        fallback: DemoData.initialProfile.tokenSpent),
    referralCode: row['referral_code'] as String? ?? '',
    referredBy: row['referred_by'] as String? ?? '',
  );
}

MealLog _mealLogFromMap(Map<String, Object?> row) => MealLog(
      id: row['id'] as String,
      slotLabel: row['slot_label'] as String,
      foodName: row['food_name'] as String,
      calories: _intValue(row['calories']),
      protein: _doubleValue(row['protein']),
      carbs: _doubleValue(row['carbs']),
      fat: _doubleValue(row['fat']),
      loggedAt: _parseDate(row['logged_at']) ?? DateTime.now(),
    );

TokenTransaction _tokenTransactionFromMap(Map<String, Object?> row) {
  return TokenTransaction(
    id: row['id']?.toString() ?? '',
    amount: _intValue(row['amount']),
    priceK: _intValue(row['price_k']),
    description: row['description']?.toString() ?? '',
    createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
  );
}

UserSettings _settingsFromMap(Map<String, Object?> row) {
  return UserSettings(
    waterReminderEnabled:
        _boolValue(row['water_reminder_enabled'], fallback: true),
    workoutReminderEnabled:
        _boolValue(row['workout_reminder_enabled'], fallback: true),
    weeklyWeightReminderEnabled:
        _boolValue(row['weekly_weight_reminder_enabled'], fallback: false),
    language: row['language']?.toString() ?? 'Tiếng Việt',
  );
}

DemoProfile _defaultProfileFor(String displayName) {
  return DemoData.initialProfile.copyWith(
    name: displayName,
    plan: SubscriptionPlan.free,
    subscriptionMonths: 0,
    tokenBalance: 0,
    tokenEarned: 0,
    tokenSpent: 0,
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
    current
  ];
  final today = DateTime.now();
  return List.generate(values.length, (index) {
    return WeightEntry(
      label: _formatDayMonth(
          today.subtract(Duration(days: values.length - index - 1))),
      weight: double.parse(values[index].toStringAsFixed(1)),
    );
  });
}

T _enumByName<T extends Enum>(List<T> values, String? raw,
    {required T fallback}) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

List<String> _decodeStringList(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => item.toString()).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

bool _parseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() == 'true';
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _isOnboardingCompleted(Map<String, Object?> row) =>
    _parseBool(row['onboarding_completed']);

String _normalizeEmail(String value) => value.trim().toLowerCase();

String _generateOtp() => (100000 + Random.secure().nextInt(900000)).toString();

String _generateUserId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return 'usr_${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

String _generateSalt() {
  final random = Random.secure();
  return List<int>.generate(8, (_) => random.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

String _hashPasswordWithSalt(String value, String salt) =>
    sha256.convert(utf8.encode('$salt:$value')).toString();

String _hashPasswordLegacy(String value) =>
    sha256.convert(utf8.encode('$_kPasswordSalt:$value')).toString();

String _generateReferralCode(String name) {
  final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  final prefix = cleanName.length > 8
      ? cleanName.substring(0, 8)
      : (cleanName.isEmpty ? 'CORE' : cleanName);
  final suffix = Random.secure().nextInt(900000) + 100000;
  return '$prefix-$suffix';
}

String _formatDayMonth(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

String _formatDate(DateTime value) => '${_formatDayMonth(value)}/${value.year}';

DateTime _recordedAtFromLabel(String label) {
  final segments = label.split('/');
  if (segments.length != 2) return DateTime.now();
  final day = int.tryParse(segments[0]);
  final month = int.tryParse(segments[1]);
  if (day == null || month == null) return DateTime.now();
  final now = DateTime.now();
  return DateTime(now.year, month, day);
}

const _kPasswordSalt = 'CHv1_2026_s@lt';

final Map<String, Product> _productById = {
  for (final product in DemoData.products) product.id: product,
};

const _schemaStatements = [
  '''
  create table if not exists users (
    id text primary key,
    email text not null unique,
    password_hash text not null,
    password_salt text not null default '',
    display_name text not null,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
  )
  ''',
  '''
  create table if not exists pending_verify (
    email text primary key,
    display_name text not null,
    password_hash text not null,
    password_salt text not null,
    otp_code text not null,
    referral_code text,
    expires_at timestamp with time zone not null,
    failed_attempts integer not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
  )
  ''',
  '''
  create table if not exists password_resets (
    email text primary key,
    otp_code text not null,
    expires_at timestamp with time zone not null,
    failed_attempts integer not null default 0,
    created_at timestamp with time zone not null default now(),
    updated_at timestamp with time zone not null default now()
  )
  ''',
  '''
  create table if not exists sessions (
    id integer primary key check (id = 1),
    user_id text not null references users(id) on delete cascade,
    created_at timestamp with time zone not null default now()
  )
  ''',
  '''
  create table if not exists user_profiles (
    user_id text primary key references users(id) on delete cascade,
    name text not null,
    age integer not null,
    gender text not null,
    height_cm numeric not null,
    weight_kg numeric not null,
    target_weight_kg numeric not null,
    goal text not null,
    activity_level text not null,
    schedule text not null,
    dietary_restrictions_json text not null default '[]',
    allergies_json text not null default '[]',
    health_conditions_json text not null default '[]',
    training_frequency text not null default '',
    focus_areas_json text not null default '[]',
    preferred_activities_json text not null default '[]',
    meal_budget text not null default '',
    cooking_time text not null default '',
    nutrition_priorities_json text not null default '[]',
    subscription_start_date timestamp with time zone,
    core_health_max_trial_expires_at timestamp with time zone,
    plan text not null,
    subscription_months integer not null default 0,
    token_balance integer not null default 0,
    token_earned integer not null default 0,
    token_spent integer not null default 0,
    referral_code text not null default '',
    referred_by text not null default '',
    onboarding_completed boolean not null default false,
    updated_at timestamp with time zone not null default now()
  )
  ''',
  'create unique index if not exists user_profiles_referral_code_idx on user_profiles(referral_code) where referral_code <> \'\'',
  '''
  create table if not exists user_settings (
    user_id text primary key references users(id) on delete cascade,
    water_reminder_enabled boolean not null default true,
    workout_reminder_enabled boolean not null default true,
    weekly_weight_reminder_enabled boolean not null default false,
    language text not null default 'Tiếng Việt',
    updated_at timestamp with time zone not null default now()
  )
  ''',
  '''
  create table if not exists weight_entries (
    id bigint generated by default as identity primary key,
    user_id text not null references users(id) on delete cascade,
    label text not null,
    weight numeric not null,
    recorded_at timestamp with time zone not null
  )
  ''',
  'create index if not exists weight_entries_user_recorded_idx on weight_entries(user_id, recorded_at)',
  '''
  create table if not exists workout_completions (
    user_id text not null references users(id) on delete cascade,
    day_number integer not null,
    completed_at timestamp with time zone not null default now(),
    primary key (user_id, day_number)
  )
  ''',
  '''
  create table if not exists meal_completions (
    user_id text not null references users(id) on delete cascade,
    day_number integer not null,
    completed_at timestamp with time zone not null default now(),
    primary key (user_id, day_number)
  )
  ''',
  '''
  create table if not exists cart_items (
    id bigint generated by default as identity primary key,
    user_id text not null references users(id) on delete cascade,
    product_id text not null,
    added_at timestamp with time zone not null default now(),
    unique (user_id, product_id)
  )
  ''',
  '''
  create table if not exists orders (
    id text primary key,
    user_id text not null references users(id) on delete cascade,
    date_label text not null,
    item_count integer not null,
    total_k integer not null,
    status_label text not null,
    created_at timestamp with time zone not null default now()
  )
  ''',
  '''
  create table if not exists meal_logs (
    id text primary key,
    user_id text not null references users(id) on delete cascade,
    date text not null,
    slot_label text not null,
    food_name text not null,
    calories integer not null,
    protein numeric not null,
    carbs numeric not null,
    fat numeric not null,
    logged_at timestamp with time zone not null
  )
  ''',
  'create index if not exists meal_logs_user_date_idx on meal_logs(user_id, date)',
  '''
  create table if not exists token_transactions (
    id text primary key,
    user_id text not null references users(id) on delete cascade,
    amount integer not null,
    price_k integer not null default 0,
    description text not null,
    created_at timestamp with time zone not null default now()
  )
  ''',
  'create index if not exists token_transactions_user_created_idx on token_transactions(user_id, created_at)',
  '''
  create table if not exists chat_sessions (
    id text primary key,
    user_id text not null references users(id) on delete cascade,
    title text not null,
    ts bigint not null,
    history_json text not null,
    category text not null default 'General',
    created_at timestamp with time zone not null default now()
  )
  ''',
];
