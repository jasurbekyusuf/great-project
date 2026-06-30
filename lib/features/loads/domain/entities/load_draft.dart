import 'package:equatable/equatable.dart';

/// Everything the create/update load form collects, normalised to the keys the
/// backend `POST /loads/` (multipart) expects. The data source turns a draft
/// into FormData, omitting every null/empty field so DRF validation never trips
/// on a blank string.
///
/// Location ids are carried as `(<kind>, <uuid>)` pairs where `kind` is one of
/// `country` / `region` / `district` — the same suffix the `/loads/available/`
/// browse filter uses (`pickup_region`, `delivery_district`, …). The free-text
/// [fromAddress] / [toAddress] are kept as a human-readable fallback so a load
/// still shows a route even when only a country was picked.
class LoadDraft extends Equatable {
  const LoadDraft({
    required this.fromAddress,
    required this.toAddress,
    required this.comment,
    this.pickupKind,
    this.pickupId,
    this.deliveryKind,
    this.deliveryId,
    this.truckTypeIds = const [],
    this.price,
    this.currencyCode,
    this.paymentType,
    this.measurementValue,
    this.measurementUnit,
    this.advancePayment,
    this.advanceCurrencyCode,
    this.pickupDate,
    this.deliveryDate,
    this.isPartial,
    this.commodity,
  });

  final String fromAddress;
  final String toAddress;
  final String comment;

  /// `country` | `region` | `district` — the `pickup_<kind>` form key.
  final String? pickupKind;
  final String? pickupId;
  final String? deliveryKind;
  final String? deliveryId;

  /// Resolved backend `truck_type` UUIDs (sent comma-separated).
  final List<String> truckTypeIds;

  /// Numeric strings (digits only); currency as an ISO-ish code ("UZS"/"USD"…).
  final String? price;
  final String? currencyCode;

  /// Already mapped to the backend enum (`cash` | `card` | `bank_transfer`).
  final String? paymentType;

  /// Single weight-or-volume value + backend unit (`ton` | `m3` | `kg` | `l`).
  final String? measurementValue;
  final String? measurementUnit;

  final String? advancePayment;
  final String? advanceCurrencyCode;

  /// ISO `yyyy-MM-dd` dates.
  final String? pickupDate;
  final String? deliveryDate;

  final bool? isPartial;
  final String? commodity;

  @override
  List<Object?> get props => [
        fromAddress,
        toAddress,
        comment,
        pickupKind,
        pickupId,
        deliveryKind,
        deliveryId,
        truckTypeIds,
        price,
        currencyCode,
        paymentType,
        measurementValue,
        measurementUnit,
        advancePayment,
        advanceCurrencyCode,
        pickupDate,
        deliveryDate,
        isPartial,
        commodity,
      ];
}
