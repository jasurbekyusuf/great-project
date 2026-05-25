import 'package:freezed_annotation/freezed_annotation.dart';

part 'load_entity.freezed.dart';

@freezed
class LoadEntity with _$LoadEntity {
  const factory LoadEntity({
    required String guid,
    required String fromAddress,
    required String toAddress,
    String? comment,
    double? price,
    String? pickupDate,
  }) = _LoadEntity;
}
