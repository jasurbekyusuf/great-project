import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements LoadsRepository {}

LoadEntity _load(String id, {String from = 'A', String to = 'B'}) =>
    LoadEntity(guid: id, fromAddress: from, toAddress: to);

List<LoadEntity> _page(int n, int count) =>
    List.generate(count, (i) => _load('p${n}_$i'));

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [loadsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive for the duration of the test.
    final sub = container.listen(
      loadsControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    return container;
  }

  test('initial build loads page 1 and reports hasMore on a full page',
      () async {
    when(
      () => repo.getLoads(
        page: any(named: 'page', that: equals(1)),
        limit: any(named: 'limit'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right(_page(1, 10)));

    final container = makeContainer();

    final list = await container.read(loadsControllerProvider.future);

    expect(list, hasLength(10));
    expect(container.read(loadsControllerProvider.notifier).hasMore, isTrue);
  });

  test('loadMore appends the next page and stops on a short final page',
      () async {
    when(
      () => repo.getLoads(
        page: any(named: 'page', that: equals(1)),
        limit: any(named: 'limit'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right(_page(1, 10)));
    when(
      () => repo.getLoads(
        page: any(named: 'page', that: equals(2)),
        limit: any(named: 'limit'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right(_page(2, 4))); // short -> no more pages

    final container = makeContainer();
    await container.read(loadsControllerProvider.future);

    await container.read(loadsControllerProvider.notifier).loadMore();

    expect(container.read(loadsControllerProvider).value, hasLength(14));
    expect(container.read(loadsControllerProvider.notifier).hasMore, isFalse);
  });

  test('applyQuery filters the visible list by from/to address', () async {
    when(
      () => repo.getLoads(
        page: any(named: 'page', that: equals(1)),
        limit: any(named: 'limit'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right([
        _load('1', from: 'Toshkent', to: 'Samarqand'),
        _load('2', from: 'Buxoro', to: 'Xiva'),
      ]),
    );

    final container = makeContainer();
    await container.read(loadsControllerProvider.future);

    container.read(loadsControllerProvider.notifier).applyQuery('toshkent');

    final list = container.read(loadsControllerProvider).value!;
    expect(list, hasLength(1));
    expect(list.single.guid, '1');
  });
}
