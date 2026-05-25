// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'truck_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TruckEntity {
  String get guid => throw _privateConstructorUsedError;
  String get fromAddress => throw _privateConstructorUsedError;
  String get toAddress => throw _privateConstructorUsedError;

  /// Create a copy of TruckEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TruckEntityCopyWith<TruckEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TruckEntityCopyWith<$Res> {
  factory $TruckEntityCopyWith(
          TruckEntity value, $Res Function(TruckEntity) then) =
      _$TruckEntityCopyWithImpl<$Res, TruckEntity>;
  @useResult
  $Res call({String guid, String fromAddress, String toAddress});
}

/// @nodoc
class _$TruckEntityCopyWithImpl<$Res, $Val extends TruckEntity>
    implements $TruckEntityCopyWith<$Res> {
  _$TruckEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TruckEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? fromAddress = null,
    Object? toAddress = null,
  }) {
    return _then(_value.copyWith(
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      fromAddress: null == fromAddress
          ? _value.fromAddress
          : fromAddress // ignore: cast_nullable_to_non_nullable
              as String,
      toAddress: null == toAddress
          ? _value.toAddress
          : toAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TruckEntityImplCopyWith<$Res>
    implements $TruckEntityCopyWith<$Res> {
  factory _$$TruckEntityImplCopyWith(
          _$TruckEntityImpl value, $Res Function(_$TruckEntityImpl) then) =
      __$$TruckEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String guid, String fromAddress, String toAddress});
}

/// @nodoc
class __$$TruckEntityImplCopyWithImpl<$Res>
    extends _$TruckEntityCopyWithImpl<$Res, _$TruckEntityImpl>
    implements _$$TruckEntityImplCopyWith<$Res> {
  __$$TruckEntityImplCopyWithImpl(
      _$TruckEntityImpl _value, $Res Function(_$TruckEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of TruckEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? fromAddress = null,
    Object? toAddress = null,
  }) {
    return _then(_$TruckEntityImpl(
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      fromAddress: null == fromAddress
          ? _value.fromAddress
          : fromAddress // ignore: cast_nullable_to_non_nullable
              as String,
      toAddress: null == toAddress
          ? _value.toAddress
          : toAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TruckEntityImpl implements _TruckEntity {
  const _$TruckEntityImpl(
      {required this.guid, required this.fromAddress, required this.toAddress});

  @override
  final String guid;
  @override
  final String fromAddress;
  @override
  final String toAddress;

  @override
  String toString() {
    return 'TruckEntity(guid: $guid, fromAddress: $fromAddress, toAddress: $toAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TruckEntityImpl &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.fromAddress, fromAddress) ||
                other.fromAddress == fromAddress) &&
            (identical(other.toAddress, toAddress) ||
                other.toAddress == toAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, guid, fromAddress, toAddress);

  /// Create a copy of TruckEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TruckEntityImplCopyWith<_$TruckEntityImpl> get copyWith =>
      __$$TruckEntityImplCopyWithImpl<_$TruckEntityImpl>(this, _$identity);
}

abstract class _TruckEntity implements TruckEntity {
  const factory _TruckEntity(
      {required final String guid,
      required final String fromAddress,
      required final String toAddress}) = _$TruckEntityImpl;

  @override
  String get guid;
  @override
  String get fromAddress;
  @override
  String get toAddress;

  /// Create a copy of TruckEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TruckEntityImplCopyWith<_$TruckEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
