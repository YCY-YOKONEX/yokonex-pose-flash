import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pose_flash/main.dart';
import 'package:pose_flash/settings_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('setup fits ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const PoseFlashApp(locale: Locale('zh')));
      await tester.pumpAndSettle();
      expect(find.text('役次元-姿势快闪'), findsWidgets);
      await tester.scrollUntilVisible(find.text('开始挑战'), 150);
      expect(tester.takeException(), isNull);
      expect(find.text('失败时执行 EMS 惩罚'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('settings survive a save and reload', () async {
    final store = SettingsStore();
    final defaults = await store.load();
    await store.save(defaults);
    final loaded = await store.load();
    expect(loaded.roundSeconds, 5);
    expect(loaded.rounds, 10);
    expect(loaded.penalties, defaults.penalties);
  });

  testWidgets('setup remains usable with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: const PoseFlashApp(locale: Locale('zh')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('开始挑战'), 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture setup for visual inspection', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    const fontPath = String.fromEnvironment('UI_TEST_FONT');
    if (fontPath.isNotEmpty) {
      await tester.runAsync(() async {
        final bytes = ByteData.sublistView(await File(fontPath).readAsBytes());
        for (final family in ['sans-serif', 'Roboto', 'Ahem']) {
          final font = FontLoader(family)..addFont(Future.value(bytes));
          await font.load();
        }
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const PoseFlashApp(locale: Locale('zh')),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await Directory('build/qa').create(recursive: true);
      await File(
        '${directory.path}/setup.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
