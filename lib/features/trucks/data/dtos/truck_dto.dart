import 'package:freezed_annotation/freezed_annotation.dart';

part 'truck_dto.freezed.dart';
part 'truck_dto.g.dart';

@freezed
class TruckDto with _$TruckDto {
  const factory TruckDto({
    String? guid,
    @JsonKey(name: 'from_address') String? fromAddress,
    @JsonKey(name: 'to_address') String? toAddress,
  }) = _TruckDto;

  factory TruckDto.fromJson(Map<String, dynamic> json) => _$TruckDtoFromJson(json);
}
