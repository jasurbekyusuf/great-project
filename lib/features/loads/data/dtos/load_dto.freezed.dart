// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'load_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LoadDto _$LoadDtoFromJson(Map<String, dynamic> json) {
  return _LoadDto.fromJson(json);
}

/// @nodoc
mixin _$LoadDto {
  String? get guid => throw _privateConstructorUsedError;
  @JsonKey(name: 'from_address')
  String? get fromAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_address')
  String? get toAddress => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  num? get price => throw _privateConstructorUsedError;
  @JsonKey(name: 'pickup_date')
  String? get pickupDate => throw _privateConstructorUsedError;

  /// Serializes this LoadDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoadDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoadDtoCopyWith<LoadDto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoadDtoCopyWith<$Res> {
  factory $LoadDtoCopyWith(LoadDto value, $Res Function(LoadDto) then) =
      _$LoadDtoCopyWithImpl<$Res, LoadDto>;
  @useResult
  $Res call(
      {String? guid,
      @JsonKey(name: 'from_address') String? fromAddress,
      @JsonKey(name: 'to_address') String? toAddress,
      String? comment,
      num? price,
      @JsonKey(name: 'pickup_date') String? pickupDate});
}

/// @nodoc
class _$LoadDtoCopyWithImpl<$Res, $Val extends LoadDto>
    implements $LoadDtoCopyWith<$Res> {
  _$LoadDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoadDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = freezed,
    Object? fromAddress = freezed,
    Object? toAddress = freezed,
    Object? comment = freezed,
    Object? price = freezed,
    Object? pickupDate = freezed,
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
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as num?,
      pickupDate: freezed == pickupDate
          ? _value.pickupDate
          : pickupDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LoadDtoImplCopyWith<$Res> implements $LoadDtoCopyWith<$Res> {
  factory _$$LoadDtoImplCopyWith(
          _$LoadDtoImpl value, $Res Function(_$LoadDtoImpl) then) =
      __$$LoadDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? guid,
      @JsonKey(name: 'from_address') String? fromAddress,
      @JsonKey(name: 'to_address') String? toAddress,
      String? comment,
      num? price,
      @JsonKey(name: 'pickup_date') String? pickupDate});
}

/// @nodoc
class __$$LoadDtoImplCopyWithImpl<$Res>
    extends _$LoadDtoCopyWithImpl<$Res, _$LoadDtoImpl>
    implements _$$LoadDtoImplCopyWith<$Res> {
  __$$LoadDtoImplCopyWithImpl(
      _$LoadDtoImpl _value, $Res Function(_$LoadDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of LoadDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = freezed,
    Object? fromAddress = freezed,
    Object? toAddress = freezed,
    Object? comment = freezed,
    Object? price = freezed,
    Object? pickupDate = freezed,
  }) {
    return _then(_$LoadDtoImpl(
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
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as num?,
      pickupDate: freezed == pickupDate
          ? _value.pickupDate
          : pickupDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LoadDtoImpl implements _LoadDto {
  const _$LoadDtoImpl(
      {this.guid,
      @JsonKey(name: 'from_address') this.fromAddress,
      @JsonKey(name: 'to_address') this.toAddress,
      this.comment,
      this.price,
      @JsonKey(name: 'pickup_date') this.pickupDate});

  factory _$LoadDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoadDtoImplFromJson(json);

  @override
  final String? guid;
  @override
  @JsonKey(name: 'from_address')
  final String? fromAddress;
  @override
  @JsonKey(name: 'to_address')
  final String? toAddress;
  @override
  final String? comment;
  @override
  final num? price;
  @override
  @JsonKey(name: 'pickup_date')
  final String? pickupDate;

  @override
  String toString() {
    return 'LoadDto(guid: $guid, fromAddress: $fromAddress, toAddress: $toAddress, comment: $comment, price: $price, pickupDate: $pickupDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadDtoImpl &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, guid, fromAddress, toAddress, comment, price, pickupDate);

  /// Create a copy of LoadDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadDtoImplCopyWith<_$LoadDtoImpl> get copyWith =>
      __$$LoadDtoImplCopyWithImpl<_$LoadDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoadDtoImplToJson(
      this,
    );
  }
}

abstract class _LoadDto implements LoadDto {
  const factory _LoadDto(
      {final String? guid,
      @JsonKey(name: 'from_address') final String? fromAddress,
      @JsonKey(name: 'to_address') final String? toAddress,
      final String? comment,
      final num? price,
      @JsonKey(name: 'pickup_date') final String? pickupDate}) = _$LoadDtoImpl;

  factory _LoadDto.fromJson(Map<String, dynamic> json) = _$LoadDtoImpl.fromJson;

  @override
  String? get guid;
  @override
  @JsonKey(name: 'from_address')
  String? get fromAddress;
  @override
  @JsonKey(name: 'to_address')
  String? get toAddress;
  @override
  String? get comment;
  @override
  num? get price;
  @override
  @JsonKey(name: 'pickup_date')
  String? get pickupDate;

  /// Create a copy of LoadDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadDtoImplCopyWith<_$LoadDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
