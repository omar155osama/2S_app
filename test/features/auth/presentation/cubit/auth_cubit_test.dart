import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sales_odoo_app/core/errors/failures.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';
import 'package:sales_odoo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_state.dart';

import 'package:sales_odoo_app/core/network/session_manager.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionManager extends Mock implements SessionManager {}

void main() {
  late AuthCubit cubit;
  late MockAuthRepository mockRepository;
  late MockSessionManager mockSessionManager;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockSessionManager = MockSessionManager();
    cubit = AuthCubit(
      repository: mockRepository,
      sessionManager: mockSessionManager,
    );
  });

  const tSession = AuthSessionModel(
    uid: 42,
    database: 'test',
    username: 'user',
    password: 'password',
    isInternalUser: true,
  );
  const tUsername = 'user';
  const tPassword = 'password';

  test('initial state should be AuthInitial', () {
    expect(cubit.state, isA<AuthInitial>());
  });

  blocTest<AuthCubit, AuthState>(
    'emits [AuthLoading, AuthSuccess] when login is successful',
    build: () {
      when(
        () => mockRepository.login(tUsername, tPassword),
      ).thenAnswer((_) async => (null, tSession));
      return cubit;
    },
    act: (cubit) => cubit.login(tUsername, tPassword),
    expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
  );

  blocTest<AuthCubit, AuthState>(
    'emits [AuthLoading, AuthError] when login fails',
    build: () {
      when(
        () => mockRepository.login(tUsername, tPassword),
      ).thenAnswer((_) async => (const ServerFailure('Error'), null));
      return cubit;
    },
    act: (cubit) => cubit.login(tUsername, tPassword),
    expect: () => [isA<AuthLoading>(), isA<AuthError>()],
  );

  blocTest<AuthCubit, AuthState>(
    'emits [AuthError] when fields are empty',
    build: () => cubit,
    act: (cubit) => cubit.login('', ''),
    expect: () => [isA<AuthError>()],
  );

  test(
    'lifecycle: new AuthCubit functions normally after old AuthCubit is closed',
    () async {
      when(
        () => mockRepository.login(tUsername, tPassword),
      ).thenAnswer((_) async => (null, tSession));

      final cubit1 = AuthCubit(
        repository: mockRepository,
        sessionManager: mockSessionManager,
      );
      await cubit1.login(tUsername, tPassword);
      await cubit1.close();

      final cubit2 = AuthCubit(
        repository: mockRepository,
        sessionManager: mockSessionManager,
      );
      await cubit2.login(tUsername, tPassword);
      expect(cubit2.state, isA<AuthSuccess>());
    },
  );
}
