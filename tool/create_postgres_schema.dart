import 'dart:io';

import 'package:corehealth_flutter/src/data/postgres_app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates CoreHealth PostgreSQL schema', () async {
    final args = Platform.executableArguments;
    final repository = PostgresAppRepository(
      host: _arg(args, '--host') ?? 'localhost',
      port: int.tryParse(_arg(args, '--port') ?? '') ?? 5432,
      database: _arg(args, '--database') ?? 'corehealth',
      username: _arg(args, '--user') ?? 'postgres',
      password: _arg(args, '--password') ?? '123456',
    );

    await repository.init();
    print('Created CoreHealth PostgreSQL schema in database corehealth.');
  });
}

String? _arg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
