import 'package:equatable/equatable.dart';

class AuthSessionModel extends Equatable {
  final int uid;
  final String database;
  final String username;
  final String password;
  final bool isInternalUser;

  const AuthSessionModel({
    required this.uid,
    required this.database,
    required this.username,
    required this.password,
    required this.isInternalUser,
  });

  @override
  List<Object?> get props => [
    uid,
    database,
    username,
    password,
    isInternalUser,
  ];
}
