import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/dtos/load_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class FakeLoadsRemoteDataSource extends LoadsRemoteDataSource {
  FakeLoadsRemoteDataSource() : super(Dio());

  // Figma "Search" mock styling: 3-letter country codes, broker names,
  // role badges, truck types and "X min oldin" timestamps.
  static const _routes = [
    ('UZB', 'Shahrisabz', 'KAZ', 'Ostona'),
    ('UZB', 'Toshkent', 'RUS', 'Orenburg'),
    ('UZB', 'Samarqand', 'KAZ', 'Almaty'),
    ('UZB', 'Buxoro', 'RUS', 'Samara'),
    ('UZB', 'Farg‘ona', 'KGZ', 'Bishkek'),
    ('UZB', 'Namangan', 'UZB', 'Nukus'),
    ('UZB', 'Andijon', 'KAZ', 'Shymkent'),
    ('UZB', 'Qarshi', 'TJK', 'Dushanbe'),
  ];

  static const _owners = [
    'ExportView LTD',
    'TransLogistic Co',
    'ExportView LTD',
    'Silk Road Cargo',
    'ExportView LTD',
    'Asia Freight',
    'ExportView LTD',
    'Caspian Lines',
  ];

  // Role badge per card — "Yuk egasi" (red), "Logist"/"LoadMe AI" (blue).
  static const _roles = [
    'Yuk egasi',
    'Logist',
    'LoadMe AI',
    'Yuk egasi',
    'LoadMe AI',
    'Logist',
    'Yuk egasi',
    'LoadMe AI',
  ];

  // Truck types shown on the destination row chip.
  static const _truckTypes = [
    'Tent',
    'Refer',
    'Isuzu Katta',
    'Sisterna',
    'Jumbo',
    'Tent',
    'Refer',
    'Jumbo',
  ];

  static const _verified = [
    true,
    false,
    true,
    true,
    false,
    false,
    true,
    false,
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
    "20 000 000 so'm",
    "20 000 000 so'm",
    '20 000 000 UZS',
    "20 000 000 so'm",
    "20 000 000 so'm",
    'Kelishiladi',
    '5 400 000 UZS',
    '1 200 USD',
  ];

  // Radius (km) shown next to the pin.
  static const _radii = [120, 120, 120, 120, 120, 15, 20, 25];

  // Relative timestamps cycling like the Figma "X min oldin" labels.
  static const _timeAgoMix = [
    '16 min oldin',
    '42 min oldin',
    '2 soat oldin',
    '5 soat oldin',
    '1 kun oldin',
    '2 kun oldin',
  ];

  // -- Helpers consumed by the presentation display provider --------------
  static String ownerNameForIndex(int i) => _owners[i % _owners.length];
  static (String, String) countriesForIndex(int i) {
    final r = _routes[i % _routes.length];
    return (r.$1, r.$3);
  }
  static String priceLabelForIndex(int i) => _priceMix[i % _priceMix.length];
  static String roleBadgeForIndex(int i) => _roles[i % _roles.length];
  static String truckTypeForIndex(int i) => _truckTypes[i % _truckTypes.length];
  static bool verifiedForIndex(int i) => _verified[i % _verified.length];
  static int radiusForIndex(int i) => _radii[i % _radii.length];
  static String timeAgoForIndex(int i) => _timeAgoMix[i % _timeAgoMix.length];
}
