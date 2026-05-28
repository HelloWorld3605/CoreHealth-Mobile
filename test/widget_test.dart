import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corehealth_flutter/src/app_controller.dart';
import 'package:corehealth_flutter/src/data/memory_app_repository.dart';
import 'package:corehealth_flutter/main.dart';

void main() {
  testWidgets('renders bootstrap state before controller is ready',
      (WidgetTester tester) async {
    final controller = AppController(
      repository: MemoryAppRepository(),
    );

    await tester.pumpWidget(CoreHealthApp(controller: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
