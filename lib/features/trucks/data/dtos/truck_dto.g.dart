// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'truck_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TruckDtoImpl _$$TruckDtoImplFromJson(Map<String, dynamic> json) =>
    _$TruckDtoImpl(
      guid: json['guid'] as String?,
      fromAddress: json['from_address'] as String?,
      toAddress: json['to_address'] as String?,
    );

Map<String, dynamic> _$$TruckDtoImplToJson(_$TruckDtoImpl instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'from_address': instance.fromAddress,
      'to_address': instance.toAddress,
    };
