import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/ui/e-rapor/widgets/rapor_list_screen.dart';
import 'package:flutter_application_1/ui/home/widgets/home_quick_menu.dart';

void main() {
  testWidgets('DIKNAS opens the DIKNAS report list', (tester) async {
    Widget? openedPage;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeQuickMenu(
            authToken: 'test-token',
            onMenuTap: (page) => openedPage = page,
          ),
        ),
      ),
    );

    await tester.tap(find.text('E-Rapor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DIKNAS'));

    expect(openedPage, isA<RaporListViewPage>());
  });

  testWidgets('IEP displays an unavailable message without opening a page', (
    tester,
  ) async {
    Widget? openedPage;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeQuickMenu(
            authToken: 'test-token',
            onMenuTap: (page) => openedPage = page,
          ),
        ),
      ),
    );

    await tester.tap(find.text('E-Rapor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IEP\nBelum tersedia'));
    await tester.pumpAndSettle();

    expect(openedPage, isNull);
    expect(find.text('Fitur IEP belum tersedia.'), findsOneWidget);
  });
}
