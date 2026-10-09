import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:store_discovery/l10n/app_localizations.dart';
import 'package:store_discovery/main.dart';

void main() {
  test('supports Traditional Chinese and English fallback', () {
    expect(
      AppLocalizations(const Locale('zh', 'TW')).queryLabel,
      '想找什麼？',
    );
    expect(
      AppLocalizations(const Locale('ja')).queryLabel,
      'What are you looking for?',
    );
  });

  testWidgets('exposes localized labels to screen readers', (tester) async {
    await tester.pumpWidget(
      const StoreDiscoveryApp(locale: Locale('zh', 'TW')),
    );

    expect(find.text('店家探索'), findsOneWidget);
    expect(find.bySemanticsLabel('使用我的位置'), findsOneWidget);
    expect(find.bySemanticsLabel('想找什麼？'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
