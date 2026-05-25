// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoadDtoImpl _$$LoadDtoImplFromJson(Map<String, dynamic> json) =>
    _$LoadDtoImpl(
      guid: json['guid'] as String?,
      fromAddress: json['from_address'] as String?,
      toAddress: json['to_address'] as String?,
      comment: json['comment'] as String?,
      price: json['price'] as num?,
      pickupDate: json['pickup_date'] as String?,
    );

Map<String, dynamic> _$$LoadDtoImplToJson(_$LoadDtoImpl instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'from_address': instance.fromAddress,
      'to_address': instance.toAddress,
      'comment': instance.comment,
      'price': instance.price,
      'pickup_date': instance.pickupDate,
    };
