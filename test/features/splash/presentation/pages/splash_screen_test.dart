import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';
import 'package:sales_odoo_app/features/splash/presentation/pages/splash_screen.dart';

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  late MockSessionManager mockSessionManager;

  setUp(() {
    mockSessionManager = MockSessionManager();
    when(() => mockSessionManager.currentUser).thenReturn(null);
    GetIt.I.registerLazySingleton<SessionManager>(() => mockSessionManager);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('SplashScreen can be constructed and renders Stack/Images', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(nextRoute: '/login')),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(5));
  });

  testWidgets('SplashScreen disposes AnimationController cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(nextRoute: '/login')),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox()); // Unmount widget
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen navigates to /login when unauthenticated', (
    tester,
  ) async {
    String? navigatedLocation;

    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            navigatedLocation = '/login';
            return const Scaffold(body: Text('Login Page'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(navigatedLocation, '/login');
  });

  testWidgets('SplashScreen navigates to /customers when authenticated', (
    tester,
  ) async {
    when(() => mockSessionManager.currentUser).thenReturn(
      const AuthSessionModel(
        uid: 1,
        database: 'db',
        username: 'u',
        password: 'p',
        isInternalUser: true,
      ),
    );

    String? navigatedLocation;

    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedLocation = '/home';
            return const Scaffold(body: Text('Customers Page'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(navigatedLocation, '/home');
  });
}
