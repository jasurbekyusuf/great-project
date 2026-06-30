import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';

/// Talks to `GET /users/me/` on the real LoadMe backend.
///
/// Response envelope is `{ success, data }`; [_unwrap] peels the `data` layer.
/// The user's display fields live in a nested `profile` object, while `id`,
/// `phone_number` and `role` sit at the top level. `role` is normalised to the
/// app's vocabulary (backend `driver` → `carrier`) and `photo` is absolutised.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  Future<ProfileEntity> getMyProfile() async {
    final res = await _dio.get<dynamic>('/users/me/');
    return _parse(_unwrap(res));
  }

  /// Saves the editable profile fields via `PATCH /users/me/`.
  ///
  /// The backend expects **multipart** form-data (same as register/avatar
  /// upload) with flat keys — `full_name`, `company_name`, `person_type`,
  /// `telegram_username`, `whatsapp_number` — NOT the nested `profile` shape the
  /// GET returns. `phone_number` is the OTP-verified login identity and is not
  /// editable here, so it is never sent. Only non-null fields are included so a
  /// partial edit never blanks an untouched value. When [photoPath] is given the
  /// chosen avatar is attached as the multipart `photo` file. Returns the
  /// re-parsed user.
  Future<ProfileEntity> updateProfile({
    String? fullName,
    String? companyName,
    String? personType,
    String? telegramUsername,
    String? whatsappNumber,
    String? photoPath,
  }) async {
    final fields = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (companyName != null) 'company_name': companyName,
      if (personType != null) 'person_type': personType,
      if (telegramUsername != null) 'telegram_username': telegramUsername,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      if (photoPath != null && photoPath.isNotEmpty)
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: photoPath.split(RegExp(r'[\\/]')).last,
        ),
    };
    final res = await _dio.patch<dynamic>(
      '/users/me/',
      data: FormData.fromMap(fields),
    );
    return _parse(_unwrap(res));
  }

  /// Maps the unwrapped `data` payload (display fields nested under `profile`,
  /// identity at the top level) into a [ProfileEntity]. Shared by GET + PATCH.
  ProfileEntity _parse(Map<String, dynamic> data) {
    final profile = data['profile'] is Map
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};

    return ProfileEntity(
      guid: (data['id'] ?? data['guid'] ?? '').toString(),
      fullName: (profile['full_name'] ??
              data['full_name'] ??
              profile['company_name'] ??
              data['company_name'] ??
              '-')
          .toString(),
      phone: (data['phone_number'] ?? data['phone'])?.toString(),
      companyName:
          (profile['company_name'] ?? data['company_name'])?.toString(),
      role: _role(data['role']),
      avatarUrl: _media((profile['photo'] ?? data['photo'])?.toString()),
      rating: _toDouble(profile['rating'] ?? data['rating']),
      verified: (profile['is_verified'] ??
              data['is_verified'] ??
              profile['verified'] ??
              false) ==
          true,
      telegramUsername:
          (profile['telegram_username'] ?? data['telegram_username'])
              ?.toString(),
      whatsappNumber:
          (profile['whatsapp_number'] ?? data['whatsapp_number'])?.toString(),
      personType: (profile['person_type'] ?? data['person_type'])?.toString(),
    );
  }

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  /// Backend roles are `shipper` | `broker` | `driver`; the app calls the last
  /// `carrier`. Tolerates either a bare string or a `[role]` list.
  String? _role(dynamic raw) {
    String? r;
    if (raw is List && raw.isNotEmpty) {
      r = raw.first?.toString();
    } else if (raw is String && raw.isNotEmpty) {
      r = raw;
    }
    if (r == null || r.isEmpty) return null;
    r = r.toLowerCase();
    return r == 'driver' ? 'carrier' : r;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Absolutises a relative `/media/...` path against the API origin (the Dio
  /// base URL minus its `/api/v1` suffix). Already-absolute URLs pass through.
  String? _media(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = _dio.options.baseUrl;
    final origin =
        base.endsWith('/api/v1') ? base.substring(0, base.length - 7) : base;
    return path.startsWith('/') ? '$origin$path' : '$origin/$path';
  }
}
