import 'package:freezed_annotation/freezed_annotation.dart';

part 'load_dto.freezed.dart';
part 'load_dto.g.dart';

@freezed
class LoadDto with _$LoadDto {
  const factory LoadDto({
    String? guid,
    @JsonKey(name: 'from_address') String? fromAddress,
    @JsonKey(name: 'to_address') String? toAddress,
    String? comment,
    num? price,
    @JsonKey(name: 'pickup_date') String? pickupDate,
  }) = _LoadDto;

  factory LoadDto.fromJson(Map<String, dynamic> json) => _$LoadDtoFromJson(json);
}
