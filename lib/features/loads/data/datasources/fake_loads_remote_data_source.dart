import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/dtos/load_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class FakeLoadsRemoteDataSource extends LoadsRemoteDataSource {
  FakeLoadsRemoteDataSource() : super(Dio());

  // Real-looking samples mirroring loadme.uz mobile view.
  static const _routes = [
    ('UZ', 'Ташкентский ра…', 'UZ', 'Ташкентский рай…'),
    ('UZ', 'Бухара', 'RU', 'Оренбург'),
    ('UZ', 'Шахрисабз', 'UZ', 'Каршинский район'),
    ('UZ', 'село Яварлик', 'RU', 'Самара'),
    ('UZ', 'Самарканд', 'UZ', 'Хива'),
    ('UZ', 'Наманган', 'UZ', 'Нукус'),
    ('UZ', 'Андижан', 'KZ', 'Алматы'),
    ('UZ', 'Фергана', 'KG', 'Бишкек'),
  ];

  static const _owners = [
    "Abdulla Karimov Parvozbek o'g'li",
    'Мужафаров Амиржон Зафарович',
    'Shaxzod Abdullaev',
    'Saydialim',
    'Ravshan Tursunov',
    'Jamshid Ergashev',
    'Bekzod Yusupov',
    'LoadMe admin',
  ];

  static final _sample = List.generate(_routes.length, (i) {
    final r = _routes[i];
    final base = DateTime(2026, 6, i + 1);
    return LoadDto(
      guid: 'fake-load-$i',
      // Country code is rendered as a pill via `countriesForIndex` — keep
      // just the address text here.
      fromAddress: r.$2,
      toAddress: r.$4,
      comment: '${10 + i * 4} m³ · ${(2 + i * 2.5).toStringAsFixed(1)} t',
      price: 1500000 + i * 250000,
      pickupDate: base.toIso8601String(),
    );
  });

  @override
  Future<PaginatedResponse<LoadDto>> getLoads({required int page, required int limit}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PaginatedResponse(count: _sample.length, result: _sample);
  }

  @override
  Future<PaginatedResponse<LoadDto>> getUserLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final filtered = _sample.take(isActive ? 5 : 3).toList();
    return PaginatedResponse(count: filtered.length, result: filtered);
  }

  @override
  Future<LoadDto> getLoadById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _sample.firstWhere(
      (e) => e.guid == id,
      orElse: () => _sample.first,
    );
  }

  @override
  Future<void> addLoad({required String fromAddress, required String toAddress, required String comment}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateLoadStatus({required String guid, required bool isActive, String? closedPlatform}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  static const _priceMix = [
    '3 250 UZS',
    'Kelishiladi',
    '5 400 000 UZS',
    'Kelishiladi',
    '1 200 USD',
    '12 500 000 UZS',
    'Kelishiladi',
    '850 USD',
  ];

  // -- Helpers consumed by the presentation display provider --------------
  static String ownerNameForIndex(int i) => _owners[i % _owners.length];
  static (String, String) countriesForIndex(int i) {
    final r = _routes[i % _routes.length];
    return (r.$1, r.$3);
  }
  static String priceLabelForIndex(int i) => _priceMix[i % _priceMix.length];
}
