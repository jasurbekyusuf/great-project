/// Auth tokens (+ optional embedded user) from the LoadMe backend.
///
/// Login, register and OTP-verify (login branch) all return the same shape:
/// `{ access, refresh, user? }`. The profile is usually fetched separately via
/// `GET /users/me/`, so [user] may be null here.
class AuthSessionDto {
  const AuthSessionDto({this.access, this.refresh, this.user});

  final String? access;
  final String? refresh;
  final Map<String, dynamic>? user;

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuthSessionDto(
      access: json['access']?.toString(),
      refresh: json['refresh']?.toString(),
      user: user is Map ? Map<String, dynamic>.from(user) : null,
    );
  }
}
