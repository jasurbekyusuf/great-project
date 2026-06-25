/// Authenticated user as surfaced by `GET /users/me/`.
///
/// Plain immutable class (no codegen): the backend nests the display fields in
/// a `profile` object while keeping `id`/`phone_number`/`role` at the top, so a
/// hand-written mapping in the data source is clearer than generated JSON glue.
class ProfileEntity {
  const ProfileEntity({
    required this.guid,
    required this.fullName,
    this.phone,
    this.companyName,
    this.role,
    this.avatarUrl,
    this.rating,
    this.verified = false,
  });

  final String guid;
  final String fullName;
  final String? phone;
  final String? companyName;

  /// App-side role: `shipper` | `broker` | `carrier` (backend `driver` → carrier).
  final String? role;

  /// Absolute avatar URL (relative `/media/...` paths are prefixed with origin).
  final String? avatarUrl;
  final double? rating;
  final bool verified;
}
