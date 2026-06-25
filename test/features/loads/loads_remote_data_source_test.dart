import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(
  dynamic data, {
  String path = '/loads/available/',
  int status = 200,
}) =>
    Response<dynamic>(
      data: data,
      statusCode: status,
      requestOptions: RequestOptions(path: path),
    );

void main() {
  late _MockDio dio;
  late LoadsRemoteDataSource ds;

  setUp(() {
    dio = _MockDio();
    ds = LoadsRemoteDataSource(dio);
  });

  group('getLoads — envelope peeling + field parsing', () {
    test('parses a {success, data:{results}} envelope into entities', () async {
      final envelope = {
        'success': true,
        'data': {
          'count': 2,
          'results': [
            {
              'id': 'abc',
              'pickup_district': {'name': 'Chilonzor'},
              'pickup_region': {'name': 'Toshkent'},
              'delivery_district': {'name': 'Olmazor'},
              'delivery_region': {'name': 'Toshkent'},
              'price': 20000000,
              'currency': {'code': 'UZS'},
              'measurement_value': 20,
              'measurement_unit': 'ton',
              'owner': {
                'display_name': 'Ali',
                'role': 'broker',
                'is_verified': true,
              },
            },
            {
              'guid': 'def',
              'from_location': 'Samarqand',
              'delivery_location': 'Buxoro',
              'measurement_value': 15,
              'measurement_unit': 'm3',
              'owner': {'is_bot': true},
            },
          ],
        },
      };
      when(
        () => dio.get<dynamic>(
          '/loads/available/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _resp(envelope));

      final loads = await ds.getLoads(page: 1, limit: 10);

      expect(loads, hasLength(2));

      final a = loads[0];
      expect(a.guid, 'abc');
      expect(a.fromAddress, 'Chilonzor, Toshkent');
      expect(a.toAddress, 'Olmazor, Toshkent');
      expect(a.priceLabel, "20 000 000 so'm");
      expect(a.weightT, 20);
      expect(a.volumeM3, isNull);
      expect(a.roleBadge, 'Logist');
      expect(a.verified, isTrue);

      final b = loads[1];
      expect(b.guid, 'def');
      expect(b.fromAddress, 'Samarqand'); // free-text *_location fallback
      expect(b.toAddress, 'Buxoro');
      expect(b.priceLabel, 'Kelishiladi'); // no price -> negotiable label
      expect(b.volumeM3, 15);
      expect(b.weightT, isNull);
      expect(b.roleBadge, 'LoadMe AI'); // owner.is_bot -> AI badge
    });

    test('tolerates a bare list payload (no envelope)', () async {
      when(
        () => dio.get<dynamic>(
          '/loads/available/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _resp([
          {'id': '1', 'pickup_location': 'A', 'delivery_location': 'B'},
        ]),
      );

      final loads = await ds.getLoads(page: 1, limit: 10);

      expect(loads, hasLength(1));
      expect(loads.single.guid, '1');
    });
  });

  group('getLoadsCount', () {
    test('reads the paginated count out of the envelope', () async {
      when(
        () => dio.get<dynamic>(
          '/loads/available/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _resp({
          'data': {'count': 42, 'results': <dynamic>[]},
        }),
      );

      expect(await ds.getLoadsCount(), 42);
    });
  });

  group('getLoadById', () {
    test('falls back to /loads/{id}/ when the public route 404s', () async {
      when(() => dio.get<dynamic>('/loads/available/x1/')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/loads/available/x1/'),
          response: Response<dynamic>(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/loads/available/x1/'),
          ),
        ),
      );
      when(() => dio.get<dynamic>('/loads/x1/')).thenAnswer(
        (_) async => _resp(
          {
            'data': {
              'id': 'x1',
              'pickup_location': 'A',
              'delivery_location': 'B',
            },
          },
          path: '/loads/x1/',
        ),
      );

      final load = await ds.getLoadById('x1');

      expect(load.guid, 'x1');
      verify(() => dio.get<dynamic>('/loads/x1/')).called(1);
    });
  });
}
