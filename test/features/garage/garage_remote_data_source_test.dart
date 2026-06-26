import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/features/garage/data/datasources/garage_remote_data_source.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(
  dynamic data, {
  String path = '/trucks/',
  int status = 200,
}) =>
    Response<dynamic>(
      data: data,
      statusCode: status,
      requestOptions: RequestOptions(path: path),
    );

/// Flatten a captured [FormData] into a plain `{key: value}` map of its text
/// fields so assertions read cleanly.
Map<String, String> _fieldsOf(Object? captured) {
  final form = captured! as FormData;
  return {for (final e in form.fields) e.key: e.value};
}

void main() {
  late _MockDio dio;
  late GarageRemoteDataSource ds;

  setUp(() {
    dio = _MockDio();
    ds = GarageRemoteDataSource(dio);
  });

  group('addVehicle — multipart POST /trucks/', () {
    test('sends model_name, truck_type, measurement + plate as form fields',
        () async {
      when(() => dio.post<dynamic>('/trucks/', data: any(named: 'data')))
          .thenAnswer((_) async => _resp({'success': true}));

      await ds.addVehicle(
        const GarageVehicle(
          id: 'local-1',
          name: 'Tent', // truck-type label — must NOT be sent
          model: 'Isuzu FVR 33',
          plate: '30 A 701 AS',
          truckTypeId: 'tt-1',
          truckModelId: 'tm-1',
          measurementValue: '8.5',
          measurementUnit: 'ton',
        ),
      );

      final captured = verify(
        () => dio.post<dynamic>('/trucks/', data: captureAny(named: 'data')),
      ).captured.single;
      final fields = _fieldsOf(captured);

      expect(fields['model_name'], 'Isuzu FVR 33');
      expect(fields['truck_model'], 'tm-1');
      expect(fields['truck_type'], 'tt-1');
      expect(fields['measurement_value'], '8.5');
      expect(fields['measurement_unit'], 'ton');
      expect(fields['plate_number'], '30 A 701 AS');
      // The human-facing type label is never part of the request body.
      expect(fields.containsValue('Tent'), isFalse);
    });

    test('omits empty/null fields instead of sending blanks', () async {
      when(() => dio.post<dynamic>('/trucks/', data: any(named: 'data')))
          .thenAnswer((_) async => _resp({'success': true}));

      await ds.addVehicle(
        const GarageVehicle(
          id: 'local-2',
          name: '',
          model: '', // empty -> no model_name
          plate: '', // empty -> no plate_number
          truckTypeId: 'tt-9',
          // measurementValue / measurementUnit null -> omitted
        ),
      );

      final captured = verify(
        () => dio.post<dynamic>('/trucks/', data: captureAny(named: 'data')),
      ).captured.single;
      final fields = _fieldsOf(captured);

      expect(fields['truck_type'], 'tt-9');
      expect(fields.containsKey('model_name'), isFalse);
      expect(fields.containsKey('truck_model'), isFalse);
      expect(fields.containsKey('plate_number'), isFalse);
      expect(fields.containsKey('measurement_value'), isFalse);
      expect(fields.containsKey('measurement_unit'), isFalse);
    });
  });
}
