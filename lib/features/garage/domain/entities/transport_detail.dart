/// Full public detail of a transport offer — the Figma "Transport ma'lumotlari"
/// screen (vehicle, route with dates, price, specs and carrier contact).
class TransportDetail {
  const TransportDetail({
    required this.id,
    required this.vehicleName,
    required this.vehicleModel,
    required this.plate,
    required this.fromCity,
    required this.fromSubtitle,
    required this.fromDate,
    required this.toCity,
    required this.toSubtitle,
    required this.toDate,
    required this.paymentLabel,
    required this.priceLabel,
    required this.loadType,
    required this.radius,
    required this.distance,
    required this.weight,
    required this.capacity,
    required this.comment,
    required this.contactName,
    required this.contactRating,
    required this.telegram,
    required this.whatsapp,
    this.phone,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
  });

  final String id;

  // Vehicle
  final String vehicleName;
  final String vehicleModel;
  final String plate;

  // Route
  final String fromCity;
  final String fromSubtitle; // "Qashqadaryo, UZ"
  final String fromDate; // "4-iyun"
  final String toCity;
  final String toSubtitle;
  final String toDate;

  // Price
  final String paymentLabel; // "Naqd"
  final String priceLabel; // "220 000 000 so'm"

  // Specs
  final String loadType; // "Dagruz (To'liq)"
  final String radius; // "10 km"
  final String distance; // "400 km"
  final String weight; // "4 t"
  final String capacity; // "34 m³"
  final String comment;

  // Contact
  final String contactName;
  final double contactRating;
  final String telegram;
  final String whatsapp;

  /// Carrier phone for the "Bog'lanish" dialer (null when the backend hides it).
  final String? phone;

  /// Pickup / delivery coordinates for the route preview. Null when the backend
  /// omits them (the map then falls back to a city-name lookup).
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
}
