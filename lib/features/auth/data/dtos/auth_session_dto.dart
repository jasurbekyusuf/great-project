import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session_dto.freezed.dart';
part 'auth_session_dto.g.dart';

@freezed
class AuthSessionDto with _$AuthSessionDto {
  const factory AuthSessionDto({
    @JsonKey(name: 'token') String? token,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    @JsonKey(name: 'user_data') Map<String, dynamic>? userData,
  }) = _AuthSessionDto;

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) => _$AuthSessionDtoFromJson(json);
}
