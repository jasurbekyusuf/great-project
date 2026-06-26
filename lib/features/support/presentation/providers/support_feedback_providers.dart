import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/support/data/datasources/support_feedback_remote_data_source.dart';

/// Support-ticket REST client over the shared [dioProvider] (bearer token
/// auto-attached). The "Fikr bildirish" screen posts through this.
final supportFeedbackDataSourceProvider =
    Provider<SupportFeedbackRemoteDataSource>((ref) {
  return SupportFeedbackRemoteDataSource(ref.watch(dioProvider));
});
