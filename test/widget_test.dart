import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:corehealth_flutter/src/app_controller.dart';
import 'package:corehealth_flutter/src/data/local_app_repository.dart';
import 'package:corehealth_flutter/main.dart';

void main() {
  testWidgets('renders bootstrap state before controller is ready',
      (WidgetTester tester) async {
    sqfliteFfiInit();
    final controller = AppController(
      repository: LocalAppRepository(databaseFactory: databaseFactoryFfi),
    );

    await tester.pumpWidget(CoreHealthApp(controller: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
