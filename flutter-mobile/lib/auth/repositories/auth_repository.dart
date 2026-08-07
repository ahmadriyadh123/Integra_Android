import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService apiService;

  AuthRepository({required this.apiService});

  Future<AuthResult> login(String username, String password) async {
    try {
      final data = await apiService.login(username, password);
      return AuthResult.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
}
