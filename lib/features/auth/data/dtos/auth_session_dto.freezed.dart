// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthSessionDto _$AuthSessionDtoFromJson(Map<String, dynamic> json) {
  return _AuthSessionDto.fromJson(json);
}

/// @nodoc
mixin _$AuthSessionDto {
  @JsonKey(name: 'token')
  String? get token => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String? get refreshToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_data')
  Map<String, dynamic>? get userData => throw _privateConstructorUsedError;

  /// Serializes this AuthSessionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthSessionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthSessionDtoCopyWith<AuthSessionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthSessionDtoCopyWith<$Res> {
  factory $AuthSessionDtoCopyWith(
          AuthSessionDto value, $Res Function(AuthSessionDto) then) =
      _$AuthSessionDtoCopyWithImpl<$Res, AuthSessionDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'token') String? token,
      @JsonKey(name: 'refresh_token') String? refreshToken,
      @JsonKey(name: 'user_data') Map<String, dynamic>? userData});
}

/// @nodoc
class _$AuthSessionDtoCopyWithImpl<$Res, $Val extends AuthSessionDto>
    implements $AuthSessionDtoCopyWith<$Res> {
  _$AuthSessionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthSessionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = freezed,
    Object? refreshToken = freezed,
    Object? userData = freezed,
  }) {
    return _then(_value.copyWith(
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      refreshToken: freezed == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String?,
      userData: freezed == userData
          ? _value.userData
          : userData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthSessionDtoImplCopyWith<$Res>
    implements $AuthSessionDtoCopyWith<$Res> {
  factory _$$AuthSessionDtoImplCopyWith(_$AuthSessionDtoImpl value,
          $Res Function(_$AuthSessionDtoImpl) then) =
      __$$AuthSessionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'token') String? token,
      @JsonKey(name: 'refresh_token') String? refreshToken,
      @JsonKey(name: 'user_data') Map<String, dynamic>? userData});
}

/// @nodoc
class __$$AuthSessionDtoImplCopyWithImpl<$Res>
    extends _$AuthSessionDtoCopyWithImpl<$Res, _$AuthSessionDtoImpl>
    implements _$$AuthSessionDtoImplCopyWith<$Res> {
  __$$AuthSessionDtoImplCopyWithImpl(
      _$AuthSessionDtoImpl _value, $Res Function(_$AuthSessionDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthSessionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = freezed,
    Object? refreshToken = freezed,
    Object? userData = freezed,
  }) {
    return _then(_$AuthSessionDtoImpl(
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      refreshToken: freezed == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String?,
      userData: freezed == userData
          ? _value._userData
          : userData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthSessionDtoImpl implements _AuthSessionDto {
  const _$AuthSessionDtoImpl(
      {@JsonKey(name: 'token') this.token,
      @JsonKey(name: 'refresh_token') this.refreshToken,
      @JsonKey(name: 'user_data') final Map<String, dynamic>? userData})
      : _userData = userData;

  factory _$AuthSessionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthSessionDtoImplFromJson(json);

  @override
  @JsonKey(name: 'token')
  final String? token;
  @override
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final Map<String, dynamic>? _userData;
  @override
  @JsonKey(name: 'user_data')
  Map<String, dynamic>? get userData {
    final value = _userData;
    if (value == null) return null;
    if (_userData is EqualUnmodifiableMapView) return _userData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AuthSessionDto(token: $token, refreshToken: $refreshToken, userData: $userData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthSessionDtoImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            const DeepCollectionEquality().equals(other._userData, _userData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, token, refreshToken,
      const DeepCollectionEquality().hash(_userData));

  /// Create a copy of AuthSessionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthSessionDtoImplCopyWith<_$AuthSessionDtoImpl> get copyWith =>
      __$$AuthSessionDtoImplCopyWithImpl<_$AuthSessionDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthSessionDtoImplToJson(
      this,
    );
  }
}

abstract class _AuthSessionDto implements AuthSessionDto {
  const factory _AuthSessionDto(
          {@JsonKey(name: 'token') final String? token,
          @JsonKey(name: 'refresh_token') final String? refreshToken,
          @JsonKey(name: 'user_data') final Map<String, dynamic>? userData}) =
      _$AuthSessionDtoImpl;

  factory _AuthSessionDto.fromJson(Map<String, dynamic> json) =
      _$AuthSessionDtoImpl.fromJson;

  @override
  @JsonKey(name: 'token')
  String? get token;
  @override
  @JsonKey(name: 'refresh_token')
  String? get refreshToken;
  @override
  @JsonKey(name: 'user_data')
  Map<String, dynamic>? get userData;

  /// Create a copy of AuthSessionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthSessionDtoImplCopyWith<_$AuthSessionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
