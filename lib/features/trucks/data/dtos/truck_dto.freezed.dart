// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'truck_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TruckDto _$TruckDtoFromJson(Map<String, dynamic> json) {
  return _TruckDto.fromJson(json);
}

/// @nodoc
mixin _$TruckDto {
  String? get guid => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_address')
  String? get fromAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_address')
  String? get toAddress => throw _privateConstructorUsedError;

  /// Serializes this TruckDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TruckDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TruckDtoCopyWith<TruckDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TruckDtoCopyWith<$Res> {
  factory $TruckDtoCopyWith(TruckDto value, $Res Function(TruckDto) then) =
      _$TruckDtoCopyWithImpl<$Res, TruckDto>;
  @useResult
  $Res call(
      {String? guid,
      @JsonKey(name: 'from_address') String? fromAddress,
      @JsonKey(name: 'to_address') String? toAddress});
}

/// @nodoc
class _$TruckDtoCopyWithImpl<$Res, $Val extends TruckDto>
    implements $TruckDtoCopyWith<$Res> {
  _$TruckDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TruckDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = freezed,
    Object? fromAddress = freezed,
    Object? toAddress = freezed,
  }) {
    return _then(_value.copyWith(
      guid: freezed == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String?,
      fromAddress: freezed == fromAddress
          ? _value.fromAddress
          : fromAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      toAddress: freezed == toAddress
          ? _value.toAddress
          : toAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TruckDtoImplCopyWith<$Res>
    implements $TruckDtoCopyWith<$Res> {
  factory _$$TruckDtoImplCopyWith(
          _$TruckDtoImpl value, $Res Function(_$TruckDtoImpl) then) =
      __$$TruckDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? guid,
      @JsonKey(name: 'from_address') String? fromAddress,
      @JsonKey(name: 'to_address') String? toAddress});
}

/// @nodoc
class __$$TruckDtoImplCopyWithImpl<$Res>
    extends _$TruckDtoCopyWithImpl<$Res, _$TruckDtoImpl>
    implements _$$TruckDtoImplCopyWith<$Res> {
  __$$TruckDtoImplCopyWithImpl(
      _$TruckDtoImpl _value, $Res Function(_$TruckDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TruckDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = freezed,
    Object? fromAddress = freezed,
    Object? toAddress = freezed,
  }) {
    return _then(_$TruckDtoImpl(
      guid: freezed == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String?,
      fromAddress: freezed == fromAddress
          ? _value.fromAddress
          : fromAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      toAddress: freezed == toAddress
          ? _value.toAddress
          : toAddress // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TruckDtoImpl implements _TruckDto {
  const _$TruckDtoImpl(
      {this.guid,
      @JsonKey(name: 'from_address') this.fromAddress,
      @JsonKey(name: 'to_address') this.toAddress});

  factory _$TruckDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TruckDtoImplFromJson(json);

  @override
  final String? guid;
  @override
  @JsonKey(name: 'from_address')
  final String? fromAddress;
  @override
  @JsonKey(name: 'to_address')
  final String? toAddress;

  @override
  String toString() {
    return 'TruckDto(guid: $guid, fromAddress: $fromAddress, toAddress: $toAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TruckDtoImpl &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.fromAddress, fromAddress) ||
                other.fromAddress == fromAddress) &&
            (identical(other.toAddress, toAddress) ||
                other.toAddress == toAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, guid, fromAddress, toAddress);

  /// Create a copy of TruckDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TruckDtoImplCopyWith<_$TruckDtoImpl> get copyWith =>
      __$$TruckDtoImplCopyWithImpl<_$TruckDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TruckDtoImplToJson(
      this,
    );
  }
}

abstract class _TruckDto implements TruckDto {
  const factory _TruckDto(
      {final String? guid,
      @JsonKey(name: 'from_address') final String? fromAddress,
      @JsonKey(name: 'to_address') final String? toAddress}) = _$TruckDtoImpl;

  factory _TruckDto.fromJson(Map<String, dynamic> json) =
      _$TruckDtoImpl.fromJson;

  @override
  String? get guid;
  @override
  @JsonKey(name: 'from_address')
  String? get fromAddress;
  @override
  @JsonKey(name: 'to_address')
  String? get toAddress;

  /// Create a copy of TruckDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TruckDtoImplCopyWith<_$TruckDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
