import 'dart:convert';
import 'dart:math';

import '../domain/login_exception.dart';
import '../domain/login_response.dart';

class MockAuthApi {
  const MockAuthApi({this.delay = const Duration(milliseconds: 700)});

  final Duration delay;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);

    if (email != 'test@test.com' || password != '1234') {
      throw const LoginException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    return LoginResponse(
      accessToken: _createJwt(email: email, expiresIn: 3600),
      refreshToken: _createJwt(email: email, expiresIn: 604800),
      expiresIn: 3600,
    );
  }

  String _createJwt({required String email, required int expiresIn}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final random = Random.secure();
    final header = _encode({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _encode({
      'sub': email,
      'iat': now,
      'exp': now + expiresIn,
      'jti': List.generate(12, (_) => random.nextInt(256)).join(),
    });
    final signature = base64Url
        .encode(List.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
    return '$header.$payload.$signature';
  }

  String _encode(Map<String, Object> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }
}
