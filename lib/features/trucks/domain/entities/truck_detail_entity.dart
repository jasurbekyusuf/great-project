class TruckDetailEntity {
  const TruckDetailEntity({
    required this.guid,
    required this.modelName,
    required this.isActive,
    this.truckType,
    this.loadCapacity,
    this.loadCapacityValue,
    this.weight,
    this.weightValue,
    this.plateNumber,
    this.trailerNumber,
    this.phone,
    this.createdTime,
    this.isPartial,
    this.minTemp,
    this.maxTemp,
    this.photo,
    this.certificates = const [],
  });

  final String guid;
  final String modelName;
  final bool isActive;
  final String? truckType;
  final String? loadCapacity;
  final String? loadCapacityValue;
  final String? weight;
  final String? weightValue;
  final String? plateNumber;
  final String? trailerNumber;
  final String? phone;
  final String? createdTime;
  final bool? isPartial;
  final String? minTemp;
  final String? maxTemp;
  final String? photo;
  final List<String> certificates;
}
