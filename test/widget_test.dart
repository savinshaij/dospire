// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dospire/main.dart';
import 'package:dospire/services/hive_storage_service.dart';
import 'package:dospire/state/app_state.dart';

class _TestHarness extends StatelessWidget {
  const _TestHarness();

  @override
  Widget build(BuildContext context) {
    final storage = HiveStorageService();
    return MultiProvider(
      providers: [
        Provider<HiveStorageService>.value(value: storage),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(storage),
        ),
      ],
      child: const DoSpireApp(),
    );
  }
}

void main() {
  testWidgets('DoSpireApp renders loading state before hydration',
      (WidgetTester tester) async {
    await tester.pumpWidget(const _TestHarness());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
