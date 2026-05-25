// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthSessionDtoImpl _$$AuthSessionDtoImplFromJson(Map<String, dynamic> json) =>
    _$AuthSessionDtoImpl(
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      userData: json['user_data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$AuthSessionDtoImplToJson(
        _$AuthSessionDtoImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refresh_token': instance.refreshToken,
      'user_data': instance.userData,
    };
