import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/saved/data/datasources/saved_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(
  dynamic data, {
  String path = '/favorites/',
  int status = 200,
}) =>
    Response<dynamic>(
      data: data,
      statusCode: status,
      requestOptions: RequestOptions(path: path),
    );

void main() {
  late _MockDio dio;
  late SavedRemoteDataSource ds;

  setUp(() {
    dio = _MockDio();
    // parseLoad is pure, so the real loads data source can share the mock Dio.
    ds = SavedRemoteDataSource(dio, LoadsRemoteDataSource(dio));
  });

  void stubGet(dynamic body) {
    when(() => dio.get<dynamic>('/favorites/'))
        .thenAnswer((_) async => _resp(body));
  }

  group('getSaved / getSavedRouteIds — wishlist shapes', () {
    // Collection: "01 List Wishlist (loads + routes)" — GET /api/v1/favorites/.
    // No response example is documented, so the parser tolerates every shape
    // the same backend's web client handles. These tests pin each one.

    test('split buckets {success, data:{loads, routes}}', () async {
      stubGet({
        'success': true,
        'data': {
          'loads': [
            {
              'id': 'L1',
              'pickup_district': {'name': 'Chilonzor'},
              'owner': {'display_name': 'Ali'},
            },
          ],
          'routes': [
            {
              'id': 'R1',
              'departure_date': '2026-07-01',
              'truck': {'id': 't1'},
            },
          ],
        },
      });

      final saved = await ds.getSaved();
      expect(saved, hasLength(1));
      expect(saved.single.id, 'L1');
      expect(saved.single.load.guid, 'L1');
      expect(saved.single.load.fromAddress, 'Chilonzor');

      final routeIds = await ds.getSavedRouteIds();
      expect(routeIds, {'R1'});
    });

    test('flat paginated data.results with {type, item} entries', () async {
      stubGet({
        'data': {
          'count': 2,
          'results': [
            {
              'id': 'fav-1',
              'type': 'load',
              'saved_at': '2026-06-01',
              'item': {
                'id': 'L1',
                'owner': {'display_name': 'Ali'},
              },
            },
            {
              'id': 'fav-2',
              'type': 'route',
              'saved_at': '2026-06-02',
              'item': {
                'id': 'R1',
                'truck': {'id': 't1'},
              },
            },
          ],
        },
      });

      final saved = await ds.getSaved();
      expect(saved.map((s) => s.id), ['L1']); // route entry is skipped

      final routeIds = await ds.getSavedRouteIds();
      expect(routeIds, {'R1'}); // load entry is skipped
    });

    test('bare list where entries are the load/route objects themselves',
        () async {
      stubGet([
        {
          'id': 'L1',
          'pickup_country': {'code': 'UZ'},
        },
        {
          'id': 'R1',
          'departure_date': '2026-07-01',
          'truck': {'id': 't1'},
        },
      ]);

      final saved = await ds.getSaved();
      expect(saved.map((s) => s.id), ['L1']);

      final routeIds = await ds.getSavedRouteIds();
      expect(routeIds, {'R1'});
    });

    test('per-card is_favorite flag round-trips on a saved load', () async {
      stubGet({
        'data': {
          'loads': [
            {
              'id': 'L1',
              'owner': {'display_name': 'Ali'},
              'is_favorite': true,
            },
          ],
        },
      });

      final saved = await ds.getSaved();
      expect(saved.single.load.isFavorite, isTrue);
    });

    test('empty / unknown payload yields no entries (never throws)', () async {
      stubGet({'data': <String, dynamic>{}});
      expect(await ds.getSaved(), isEmpty);
      expect(await ds.getSavedRouteIds(), isEmpty);
    });
  });

  group('mutations hit the collection sub-routes', () {
    test('addSaved POSTs /favorites/loads/{id}/ and echoes the load id',
        () async {
      when(() => dio.post<dynamic>('/favorites/loads/L1/'))
          .thenAnswer((_) async => _resp(null));

      expect(await ds.addSaved('L1'), 'L1');
      verify(() => dio.post<dynamic>('/favorites/loads/L1/')).called(1);
    });

    test('removeSaved DELETEs /favorites/loads/{id}/', () async {
      when(() => dio.delete<dynamic>('/favorites/loads/L1/'))
          .thenAnswer((_) async => _resp(null));

      await ds.removeSaved('L1');
      verify(() => dio.delete<dynamic>('/favorites/loads/L1/')).called(1);
    });

    test('addSavedRoute POSTs /favorites/routes/{id}/', () async {
      when(() => dio.post<dynamic>('/favorites/routes/R1/'))
          .thenAnswer((_) async => _resp(null));

      await ds.addSavedRoute('R1');
      verify(() => dio.post<dynamic>('/favorites/routes/R1/')).called(1);
    });

    test('removeSavedRoute DELETEs /favorites/routes/{id}/', () async {
      when(() => dio.delete<dynamic>('/favorites/routes/R1/'))
          .thenAnswer((_) async => _resp(null));

      await ds.removeSavedRoute('R1');
      verify(() => dio.delete<dynamic>('/favorites/routes/R1/')).called(1);
    });
  });
}
