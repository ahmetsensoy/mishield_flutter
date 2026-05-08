import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mishield_flutter/config/remote_app_config.dart';
import 'package:mishield_flutter/core/theme/app_theme.dart';
import 'package:mishield_flutter/features/home/home_page.dart';

void main() {
  testWidgets('HomePage builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildMiShieldTheme(),
        home: const HomePage(
          config: ResolvedAppConfig(
            primaryDns: '1.1.1.1',
            secondaryDns: '1.0.0.1',
            showAds: false,
          ),
        ),
      ),
    );
    expect(find.text('MiShield'), findsWidgets);
  });
}
