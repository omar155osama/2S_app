import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockSharedPreferences mockSharedPreferences;
  late MockConnectivity mockConnectivity;

  setUp(() async {
    mockSharedPreferences = MockSharedPreferences();
    mockConnectivity = MockConnectivity();

    when(() => mockSharedPreferences.getString(any())).thenReturn(null);
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);

    await sl.reset();
  });

  test('DI initialization does not throw', () async {
    expect(
      () async => await initDI(
        sharedPreferences: mockSharedPreferences,
        connectivity: mockConnectivity,
        testOdooUrl: 'https://demo.odoo.com',
        testOdooDatabase: 'demo',
      ),
      returnsNormally,
    );
  });

  testWidgets('App starts and initial route renders correctly', (
    WidgetTester tester,
  ) async {
    await initDI(
      sharedPreferences: mockSharedPreferences,
      connectivity: mockConnectivity,
      testOdooUrl: 'https://demo.odoo.com',
      testOdooDatabase: 'demo',
    );

    // Build our app and trigger frames until splash animation and navigation finish.
    await tester.pumpWidget(const SalesOdooApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify that the splash screen completes and navigates to login page.
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
