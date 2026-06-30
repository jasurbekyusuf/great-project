import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/feedback/data/feedback_remote_data_source.dart';

/// Feedback REST client over the shared [dioProvider] (bearer auto-attached).
final feedbackDataSourceProvider = Provider<FeedbackRemoteDataSource>((ref) {
  return FeedbackRemoteDataSource(ref.watch(dioProvider));
});

/// The complaint reason list for the report sheet — fetched once and cached for
/// the session (the picker re-uses it across loads / routes).
final complaintTypesProvider = FutureProvider<List<ComplaintType>>((ref) {
  return ref.watch(feedbackDataSourceProvider).getComplaintTypes();
});

/// Tracks which listings the viewer has contacted ("Bog'lanish" → dialer) this
/// session, keyed by load guid / transport-route id. The owner-card Baholash /
/// Shikoyat chips stay gated behind the "you must work with them first" modal
/// until the id lands here, mirroring the real flow: contact, then rate/report.
///
/// Session-scoped on purpose — contacting is a soft, per-run signal (the
/// backend has no "have I contacted X" endpoint), so it resets on relaunch.
final contactedProvider =
    NotifierProvider<ContactedNotifier, Set<String>>(ContactedNotifier.new);

class ContactedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  /// Records that the viewer contacted [id]; lifts the rate/report gate for it.
  void markContacted(String id) {
    if (id.isEmpty || state.contains(id)) return;
    state = {...state, id};
  }

  bool hasContacted(String? id) => id != null && state.contains(id);
}
