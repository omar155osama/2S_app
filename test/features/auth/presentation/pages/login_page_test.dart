import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:sales_odoo_app/features/auth/presentation/pages/login_page.dart';
import 'package:sales_odoo_app/features/auth/presentation/widgets/login_form.dart';
import 'package:bloc_test/bloc_test.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    GetIt.I.registerFactory<AuthCubit>(() => mockAuthCubit);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: LoginPage());
  }

  testWidgets('LoginPage renders correctly', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // user, pass
    expect(find.byType(ElevatedButton), findsOneWidget); // login button
  });

  testWidgets('shows loading indicator when state is AuthLoading', (
    tester,
  ) async {
    when(() => mockAuthCubit.state).thenReturn(AuthLoading());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when state is AuthError', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(const AuthError('Bad login'));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Bad login'), findsOneWidget);
  });

  testWidgets('calls login when button is pressed', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.login('user', 'pass')).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.byType(TextFormField).first, 'user');
    await tester.enterText(find.byType(TextFormField).last, 'pass');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(() => mockAuthCubit.login('user', 'pass')).called(1);
  });

  testWidgets(
    'creates new AuthCubit instance via GetIt factory when LoginPage mounts',
    (tester) async {
      var instanceCount = 0;
      GetIt.I.unregister<AuthCubit>();
      GetIt.I.registerFactory<AuthCubit>(() {
        instanceCount++;
        final cubit = MockAuthCubit();
        when(() => cubit.state).thenReturn(AuthInitial());
        return cubit;
      });

      await tester.pumpWidget(buildTestWidget());
      expect(instanceCount, 1);

      await tester.pumpWidget(const SizedBox()); // Unmount
      await tester.pumpWidget(buildTestWidget()); // Remount
      expect(instanceCount, 2);
    },
  );
}
