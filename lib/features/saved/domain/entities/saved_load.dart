import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

/// One "Saqlanganlar" entry: the enriched [load] plus the un-save key [id].
///
/// Favorites are keyed by the load id (`DELETE /favorites/loads/{id}/`), so
/// [id] always equals [LoadEntity.guid].
class SavedLoad {
  const SavedLoad({required this.id, required this.load});

  final String id;
  final LoadEntity load;
}
