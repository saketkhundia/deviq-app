import 'package:deviq/core/storage/app_storage.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSecure extends Mock implements SecureStore {}

/// Full-app boot regression: with no stored session the app must land on
/// Login without red-screening. Fixed pumps (not settle) because the
/// splash spinner animates indefinitely by design.
void main() {
  testWidgets('cold boot without session shows login', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    final secure = _FakeSecure();
    when(() => secure.readSession()).thenAnswer((_) async => null);
    await t.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWithValue(secure)],
        child: const DevIQApp(),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
