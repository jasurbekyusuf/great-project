import 'package:loadme_mobile/features/garage/data/datasources/garage_data_source.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';

/// In-memory garage data until the backend lands. Route toggles/deletes mutate
/// the in-memory list so they persist for the session.
class FakeGarageDataSource implements GarageDataSource {
  final List<GarageVehicle> _vehicles = [
    const GarageVehicle(id: 'v1', name: 'Isuzu Katta', model: 'Isuzu FVR 33', plate: '30 A 701 AS'),
    const GarageVehicle(id: 'v2', name: 'Isuzu Katta', model: 'Isuzu FVR 33', plate: '30 A 702 AA'),
  ];

  final List<GarageRoute> _routes = [
    const GarageRoute(
      id: 'r1',
      name: 'Isuzu Katta',
      priceLabel: "20 000 000 so'm",
      fromCity: 'Shahrisabz',
      fromCountry: 'UZB',
      toCity: 'Ostona',
      toCountry: 'KZ',
      distanceKm: 328,
      weightT: 33,
      loadKind: "To'liq",
      active: true,
    ),
    const GarageRoute(
      id: 'r2',
      name: 'Isuzu Katta',
      priceLabel: "20 000 000 so'm",
      fromCity: 'Shahrisabz',
      fromCountry: 'UZB',
      toCity: 'Ostona',
      toCountry: 'KZ',
      distanceKm: 328,
      weightT: 33,
      loadKind: "To'liq",
      active: false,
    ),
  ];

  // A handful of distinct details so different transports show different data.
  static const _details = <TransportDetail>[
    TransportDetail(
      id: 'd0',
      vehicleName: 'Isuzu Katta',
      vehicleModel: 'Isuzu FVR 33',
      plate: '60 O 506 KB',
      fromCity: 'Shahrisabz,',
      fromSubtitle: 'Qashqadaryo, UZ',
      fromDate: '4-iyun',
      toCity: 'Petropavlovsk-Kamchatskiy',
      toSubtitle: 'Kamchatka, RU',
      toDate: '8-iyun',
      paymentLabel: 'Naqd',
      priceLabel: "220 000 000 so'm",
      loadType: "Dagruz (To'liq)",
      radius: '10 km',
      distance: '400 km',
      weight: '4 t',
      capacity: '34 m³',
      comment: 'Temperature inside truck may depend on the weather outside',
      contactName: 'Bahodir Abdullayev',
      contactRating: 4.5,
      telegram: '@calltome',
      whatsapp: '@callmexport',
    ),
    TransportDetail(
      id: 'd1',
      vehicleName: 'MAN TGX',
      vehicleModel: 'MAN TGX 18.440',
      plate: '01 A 123 BB',
      fromCity: 'Toshkent,',
      fromSubtitle: 'Toshkent, UZ',
      fromDate: '5-iyun',
      toCity: 'Almaty',
      toSubtitle: 'Almaty, KZ',
      toDate: '7-iyun',
      paymentLabel: 'Naqd',
      priceLabel: "18 500 000 so'm",
      loadType: "To'liq",
      radius: '15 km',
      distance: '870 km',
      weight: '20 t',
      capacity: '92 m³',
      comment: 'Tent / Shtora, GPS bilan jihozlangan',
      contactName: 'Ivan Petrov',
      contactRating: 4.8,
      telegram: '@ivantrans',
      whatsapp: '@ivancargo',
    ),
    TransportDetail(
      id: 'd2',
      vehicleName: 'Mercedes Actros',
      vehicleModel: 'Actros 2545',
      plate: '40 B 777 CD',
      fromCity: 'Samarqand,',
      fromSubtitle: 'Samarqand, UZ',
      fromDate: '6-iyun',
      toCity: 'Moskva',
      toSubtitle: 'Moskva, RU',
      toDate: '12-iyun',
      paymentLabel: 'Naqd',
      priceLabel: '1 200 USD',
      loadType: 'Refrijerator',
      radius: '20 km',
      distance: '3 200 km',
      weight: '22 t',
      capacity: '86 m³',
      comment: 'Sovuq yuklar uchun, -18°C rejim',
      contactName: 'Caspian Lines',
      contactRating: 4.6,
      telegram: '@caspian',
      whatsapp: '@caspianline',
    ),
    TransportDetail(
      id: 'd3',
      vehicleName: 'Isuzu Forward',
      vehicleModel: 'Isuzu NQR 75',
      plate: '10 C 456 EF',
      fromCity: 'Buxoro,',
      fromSubtitle: 'Buxoro, UZ',
      fromDate: '4-iyun',
      toCity: 'Bishkek',
      toSubtitle: 'Chuy, KG',
      toDate: '6-iyun',
      paymentLabel: 'Naqd',
      priceLabel: '5 400 000 UZS',
      loadType: 'Dagruz',
      radius: '25 km',
      distance: '720 km',
      weight: '5 t',
      capacity: '34 m³',
      comment: 'Kichik yuklar, shahar ichi yetkazib berish ham bor',
      contactName: 'Asia Freight',
      contactRating: 4.4,
      telegram: '@asiafreight',
      whatsapp: '@asiacargo',
    ),
  ];

  @override
  Future<List<GarageVehicle>> getVehicles() async {
    await _delay();
    return List.unmodifiable(_vehicles);
  }

  @override
  Future<void> addVehicle(GarageVehicle vehicle) async {
    await _delay();
    _vehicles.add(vehicle);
  }

  @override
  Future<List<GarageRoute>> getRoutes() async {
    await _delay();
    return List.unmodifiable(_routes);
  }

  @override
  Future<void> addRoute(GarageRoute route) async {
    await _delay();
    _routes.insert(0, route);
  }

  @override
  Future<TransportDetail> getTransportDetail(String id) async {
    await _delay();
    // Deterministic per id → different transports show different details.
    return _details[id.hashCode.abs() % _details.length];
  }

  @override
  Future<void> toggleRoute(String id) async {
    await _delay();
    final i = _routes.indexWhere((r) => r.id == id);
    if (i != -1) _routes[i] = _routes[i].copyWith(active: !_routes[i].active);
  }

  @override
  Future<void> deleteRoute(String id) async {
    await _delay();
    _routes.removeWhere((r) => r.id == id);
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 150));
}
