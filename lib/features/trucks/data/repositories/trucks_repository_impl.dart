import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/data/dtos/truck_dto.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';

class TrucksRepositoryImpl implements TrucksRepository {
  TrucksRepositoryImpl(this._remote);
  final TrucksRemoteDataSource _remote;
  static const _tag = 'TrucksRepository';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<List<TruckEntity>> getTrucks({required int page, required int limit}) =>
      _guard(() async {
        final response = await _remote.getTrucks(page: page, limit: limit);
        return response.result.map(_mapTruck).toList();
      });

  @override
  AsyncResult<List<TruckEntity>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  }) =>
      _guard(() async {
        final response = await _remote.getMyPostTrucks(
          page: page,
          limit: limit,
          isActive: isActive,
        );
        return response.result.map(_mapTruck).toList();
      });

  @override
  AsyncResult<List<TruckEntity>> getMyTrucks({required int page, required int limit}) =>
      _guard(() async {
        final response = await _remote.getMyTrucks(page: page, limit: limit);
        return response.result.map(_mapTruck).toList();
      });

  @override
  AsyncResult<TruckDetailEntity> getTruckById(String id) => _guard(() async {
        final json = await _remote.getTruckById(id);
        return TruckDetailEntity(
          guid: _string(json['guid']).isEmpty ? id : _string(json['guid']),
          modelName: _string(json['model_name'], fallback: '-'),
          isActive: json['is_active'] == true,
          truckType: _localizedName(json['truck_types_id_data']),
          loadCapacity: _stringOrNull(json['load_capacity']),
          loadCapacityValue: _firstListValue(json['load_capacity_value']),
          weight: _stringOrNull(json['weight']),
          weightValue: _firstListValue(json['weight_value']),
          plateNumber: _stringOrNull(json['plate_number']),
          trailerNumber: _stringOrNull(json['trailer_number']),
          phone: _nestedString(json['users_id_data'], 'phone'),
          createdTime: _stringOrNull(json['created_time']),
          isPartial: json['is_partial'] is bool ? json['is_partial'] as bool : null,
          minTemp: _stringOrNull(json['min_temp']),
          maxTemp: _stringOrNull(json['max_temp']),
          photo: _stringOrNull(json['photo']),
          certificates: _stringList(json['certificates']),
        );
      });

  @override
  AsyncResult<void> updatePostTruckStatus({required String guid, required bool isActive}) =>
      _guard(() => _remote.updatePostTruckStatus(guid: guid, isActive: isActive));

  @override
  AsyncResult<void> updateTruckStatus({required String guid, required bool isActive}) =>
      _guard(() => _remote.updateTruckStatus(guid: guid, isActive: isActive));

  // ---- mapping helpers (unchanged) ---------------------------------------

  TruckEntity _mapTruck(TruckDto e) => TruckEntity(
        guid: e.guid ?? '',
        fromAddress: e.fromAddress ?? '-',
        toAddress: e.toAddress ?? '-',
      );

  String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString() ?? fallback;
    return text.isEmpty ? fallback : text;
  }

  String? _stringOrNull(Object? value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  String? _nestedString(Object? source, String key) {
    if (source is! Map) return null;
    return _stringOrNull(source[key]);
  }

  String? _localizedName(Object? source) {
    if (source is! Map) return null;
    return _stringOrNull(source['name_uz']) ??
        _stringOrNull(source['name_ru']) ??
        _stringOrNull(source['name_en']) ??
        _stringOrNull(source['name']);
  }

  String? _firstListValue(Object? source) {
    if (source is List && source.isNotEmpty) return _stringOrNull(source.first);
    return _stringOrNull(source);
  }

  List<String> _stringList(Object? source) {
    if (source is! List) return const [];
    return source.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
