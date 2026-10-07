import 'package:sales_odoo_app/features/auth/data/models/auth_session_model.dart';

class SessionManager {
  AuthSessionModel? currentUser;

  bool get isAuthenticated => currentUser != null;
}
