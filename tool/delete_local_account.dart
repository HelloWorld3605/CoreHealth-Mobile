import 'dart:io';
import 'package:postgres/postgres.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first.trim().isEmpty) {
    stderr.writeln('Usage: dart run tool/delete_local_account.dart <email>');
    exitCode = 64;
    return;
  }

  final email = args.first.trim().toLowerCase();

  final host = Platform.environment['COREHEALTH_POSTGRES_HOST'] ?? 'localhost';
  final database = Platform.environment['COREHEALTH_POSTGRES_DATABASE'] ?? 'corehealth';
  final username = Platform.environment['COREHEALTH_POSTGRES_USER'] ?? 'postgres';
  final password = Platform.environment['COREHEALTH_POSTGRES_PASSWORD'] ?? '123456';
  final port = int.tryParse(Platform.environment['COREHEALTH_POSTGRES_PORT'] ?? '') ?? 5432;

  stdout.writeln('Connecting to Postgres database "$database" at $host:$port...');
  final db = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    final result = await db.execute(
      Sql.named('delete from users where lower(email) = @email'),
      parameters: {'email': email},
    );

    final affected = result.affectedRows;
    if (affected == 0) {
      stdout.writeln('No account found for $email');
    } else {
      stdout.writeln('Deleted $affected account(s) for $email');
    }
  } finally {
    await db.close();
  }
}
