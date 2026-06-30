import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/features/magnit/data/datasources/magnit_remote_data_source.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_activation.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(
  dynamic data, {
  String path = '/trucks/routes/magnet/',
  int status = 200,
}) =>
    Response<dynamic>(
      data: data,
      statusCode: status,
      requestOptions: RequestOptions(path: path),
    );

void main() {
  late _MockDio dio;
  late MagnitRemoteDataSource ds;

  setUp(() {
    dio = _MockDio();
    ds = MagnitRemoteDataSource(dio);
  });

  group('getTruckTypes — envelope peeling + field parsing', () {
    test('parses a {success, data:[...]} bare-list envelope into types',
        () async {
      final envelope = {
        'success': true,
        'data': [
          {'id': 'tt-1', 'name': 'Tent'},
          {'guid': 'tt-2', 'name_ru': 'Рефрижератор'}, // guid + name_ru
          {'id': 'tt-3'}, // no name -> skipped
          {'name': 'orphan'}, // no id -> skipped
        ],
      };
      when(() => dio.get<dynamic>('/trucks/types/'))
          .thenAnswer((_) async => _resp(envelope, path: '/trucks/types/'));

      final types = await ds.getTruckTypes();

      expect(types, hasLength(2));
      expect(types[0].id, 'tt-1');
      expect(types[0].name, 'Tent');
      expect(types[1].id, 'tt-2'); // guid fallback
      expect(types[1].name, 'Рефрижератор'); // name_ru fallback
    });

    test('tolerates a paginated data.results payload', () async {
      when(() => dio.get<dynamic>('/trucks/types/')).thenAnswer(
        (_) async => _resp(
          {
            'data': {
              'results': [
                {'id': 'r1', 'name': 'Ref'},
              ],
            },
          },
          path: '/trucks/types/',
        ),
      );

      final types = await ds.getTruckTypes();

      expect(types.single.id, 'r1');
      expect(types.single.name, 'Ref');
    });
  });

  group('getTruckModels — catalogue parsing', () {
    test('hits /trucks/models/ and reads name or model_name', () async {
      when(() => dio.get<dynamic>('/trucks/models/')).thenAnswer(
        (_) async => _resp(
          {
            'success': true,
            'data': [
              {'id': 'm1', 'model_name': 'Volvo FH'}, // model_name fallback
              {'id': 'm2', 'name': 'MAN TGX'},
              {'model_name': 'orphan'}, // no id -> skipped
            ],
          },
          path: '/trucks/models/',
        ),
      );

      final models = await ds.getTruckModels();

      expect(models, hasLength(2));
      expect(models[0].id, 'm1');
      expect(models[0].name, 'Volvo FH'); // model_name fallback
      expect(models[1].id, 'm2');
      expect(models[1].name, 'MAN TGX');
    });
  });

  group('activate — request body + response parsing', () {
    test('sends truck_type plus only the non-null location keys', () async {
      when(
        () => dio.post<dynamic>(
          '/trucks/routes/magnet/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _resp({
          'success': true,
          'data': {
            'route': {'id': 'route-9'},
          },
        }),
      );

      final result = await ds.activate(
        truckType: 'tt-1',
        pickupCountry: 'c-uz',
        pickupRegion: 'r-tash',
        deliveryRegion: 'r-sam',
        deadheadRadiusKm: 100,
      );

      expect(result.status, MagnitStatus.activated);
      expect(result.routeId, 'route-9');

      final body = verify(
        () => dio.post<dynamic>(
          '/trucks/routes/magnet/',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(body['truck_type'], 'tt-1');
      expect(body['pickup_country'], 'c-uz');
      expect(body['pickup_region'], 'r-tash');
      expect(body['delivery_region'], 'r-sam');
      // The route contract types deadhead_radius_km as a string ("100").
      expect(body['deadhead_radius_km'], '100');
      // Nulls must be omitted, never sent as empty strings, so backend
      // validation never trips on a blank filter id.
      expect(body.containsKey('pickup_district'), isFalse);
      expect(body.containsKey('delivery_country'), isFalse);
      expect(body.containsKey('delivery_district'), isFalse);
    });

    test('maps a {status: truck_required} body to truckRequired', () async {
      when(
        () => dio.post<dynamic>(
          '/trucks/routes/magnet/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _resp({
          'success': true,
          'data': {'status': 'truck_required'},
        }),
      );

      final result = await ds.activate(truckType: 'tt-1');

      expect(result.status, MagnitStatus.truckRequired);
      expect(result.routeId, isNull);
    });

    test('reads a route id from a bare {data:{id}} body', () async {
      when(
        () => dio.post<dynamic>(
          '/trucks/routes/magnet/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _resp({
          'data': {'id': 'flat-7'},
        }),
      );

      final result = await ds.activate(truckType: 'tt-1');

      expect(result.status, MagnitStatus.activated);
      expect(result.routeId, 'flat-7');
    });
  });
}
