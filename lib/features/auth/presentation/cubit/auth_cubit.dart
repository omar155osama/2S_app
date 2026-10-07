import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sales_odoo_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final SessionManager sessionManager;

  AuthCubit({required this.repository, required this.sessionManager})
    : super(AuthInitial());

  Future<void> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      emit(const AuthError('Username and password are required.'));
      return;
    }

    if (state is AuthLoading) return;

    emit(AuthLoading());

    final result = await repository.login(username, password);
    final failure = result.$1;
    final session = result.$2;

    if (failure != null) {
      emit(AuthError(failure.message));
    } else if (session != null) {
      sessionManager.currentUser = session;
      emit(AuthSuccess(session));
    }
  }
}
