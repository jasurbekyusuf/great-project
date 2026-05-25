// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'load_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LoadEntity {
  String get guid => throw _privateConstructorUsedError;
  String get fromAddress => throw _privateConstructorUsedError;
  String get toAddress => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  double? get price => throw _privateConstructorUsedError;
  String? get pickupDate => throw _privateConstructorUsedError;

  /// Create a copy of LoadEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoadEntityCopyWith<LoadEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadEntityCopyWith<$Res> {
  factory $LoadEntityCopyWith(
          LoadEntity value, $Res Function(LoadEntity) then) =
      _$LoadEntityCopyWithImpl<$Res, LoadEntity>;
  @useResult
  $Res call(
      {String guid,
      String fromAddress,
      String toAddress,
      String? comment,
      double? price,
      String? pickupDate});
}

/// @nodoc
class _$LoadEntityCopyWithImpl<$Res, $Val extends LoadEntity>
    implements $LoadEntityCopyWith<$Res> {
  _$LoadEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoadEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? fromAddress = null,
    Object? toAddress = null,
    Object? comment = freezed,
    Object? price = freezed,
    Object? pickupDate = freezed,
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
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      pickupDate: freezed == pickupDate
          ? _value.pickupDate
          : pickupDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoadEntityImplCopyWith<$Res>
    implements $LoadEntityCopyWith<$Res> {
  factory _$$LoadEntityImplCopyWith(
          _$LoadEntityImpl value, $Res Function(_$LoadEntityImpl) then) =
      __$$LoadEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String guid,
      String fromAddress,
      String toAddress,
      String? comment,
      double? price,
      String? pickupDate});
}

/// @nodoc
class __$$LoadEntityImplCopyWithImpl<$Res>
    extends _$LoadEntityCopyWithImpl<$Res, _$LoadEntityImpl>
    implements _$$LoadEntityImplCopyWith<$Res> {
  __$$LoadEntityImplCopyWithImpl(
      _$LoadEntityImpl _value, $Res Function(_$LoadEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoadEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? fromAddress = null,
    Object? toAddress = null,
    Object? comment = freezed,
    Object? price = freezed,
    Object? pickupDate = freezed,
  }) {
    return _then(_$LoadEntityImpl(
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
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      pickupDate: freezed == pickupDate
          ? _value.pickupDate
          : pickupDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$LoadEntityImpl implements _LoadEntity {
  const _$LoadEntityImpl(
      {required this.guid,
      required this.fromAddress,
      required this.toAddress,
      this.comment,
      this.price,
      this.pickupDate});

  @override
  final String guid;
  @override
  final String fromAddress;
  @override
  final String toAddress;
  @override
  final String? comment;
  @override
  final double? price;
  @override
  final String? pickupDate;

  @override
  String toString() {
    return 'LoadEntity(guid: $guid, fromAddress: $fromAddress, toAddress: $toAddress, comment: $comment, price: $price, pickupDate: $pickupDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadEntityImpl &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.fromAddress, fromAddress) ||
                other.fromAddress == fromAddress) &&
            (identical(other.toAddress, toAddress) ||
                other.toAddress == toAddress) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.pickupDate, pickupDate) ||
                other.pickupDate == pickupDate));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, guid, fromAddress, toAddress, comment, price, pickupDate);

  /// Create a copy of LoadEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadEntityImplCopyWith<_$LoadEntityImpl> get copyWith =>
      __$$LoadEntityImplCopyWithImpl<_$LoadEntityImpl>(this, _$identity);
}

abstract class _LoadEntity implements LoadEntity {
  const factory _LoadEntity(
      {required final String guid,
      required final String fromAddress,
      required final String toAddress,
      final String? comment,
      final double? price,
      final String? pickupDate}) = _$LoadEntityImpl;

  @override
  String get guid;
  @override
  String get fromAddress;
  @override
  String get toAddress;
  @override
  String? get comment;
  @override
  double? get price;
  @override
  String? get pickupDate;

  /// Create a copy of LoadEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadEntityImplCopyWith<_$LoadEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
