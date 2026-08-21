import '../../features/auth/domain/login_response.dart';

class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  LoginResponse? loginResponse;
  String? email;

  void save({required String email, required LoginResponse response}) {
    this.email = email;
    loginResponse = response;
  }

  void clear() {
    email = null;
    loginResponse = null;
  }
}
