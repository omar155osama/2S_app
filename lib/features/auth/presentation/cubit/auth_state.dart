import 'package:equatable/equatable.dart';
import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final AuthSessionModel session;

  const AuthSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
