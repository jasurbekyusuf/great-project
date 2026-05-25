import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String token,
    String? refreshToken,
    String? userGuid,
    String? fullName,
  }) = _AuthSession;
}
