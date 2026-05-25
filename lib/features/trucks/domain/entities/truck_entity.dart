import 'package:freezed_annotation/freezed_annotation.dart';

part 'truck_entity.freezed.dart';

@freezed
class TruckEntity with _$TruckEntity {
  const factory TruckEntity({
    required String guid,
    required String fromAddress,
    required String toAddress,
  }) = _TruckEntity;
}
