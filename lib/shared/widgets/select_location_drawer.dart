import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors web `SelectLocationDrawer` / `SelectDestinationDrawer`:
// search-able list of regions/cities with country grouping. Backed by a fake
// in-memory dataset until backend wiring is added.
class LocationItem {
  const LocationItem({required this.id, required this.title, required this.country});
  final String id;
  final String title;
  final String country; // ISO-2: UZ, KZ, KG, RU, TJ
}

const _fakeLocations = <LocationItem>[
  LocationItem(id: 'uz-tashkent', title: 'Tashkent', country: 'UZ'),
  LocationItem(id: 'uz-samarkand', title: 'Samarqand', country: 'UZ'),
  LocationItem(id: 'uz-bukhara', title: 'Buxoro', country: 'UZ'),
  LocationItem(id: 'uz-andijan', title: 'Andijon', country: 'UZ'),
  LocationItem(id: 'uz-fergana', title: "Farg'ona", country: 'UZ'),
  LocationItem(id: 'uz-namangan', title: 'Namangan', country: 'UZ'),
  LocationItem(id: 'uz-nukus', title: 'Nukus', country: 'UZ'),
  LocationItem(id: 'uz-khiva', title: 'Xiva', country: 'UZ'),
  LocationItem(id: 'kz-almaty', title: 'Almaty', country: 'KZ'),
  LocationItem(id: 'kz-astana', title: 'Astana', country: 'KZ'),
  LocationItem(id: 'kz-shymkent', title: 'Shymkent', country: 'KZ'),
  LocationItem(id: 'kg-bishkek', title: 'Bishkek', country: 'KG'),
  LocationItem(id: 'kg-osh', title: 'Osh', country: 'KG'),
  LocationItem(id: 'ru-moscow', title: 'Moscow', country: 'RU'),
  LocationItem(id: 'ru-spb', title: 'Saint Petersburg', country: 'RU'),
  LocationItem(id: 'ru-kazan', title: 'Kazan', country: 'RU'),
  LocationItem(id: 'tj-dushanbe', title: 'Dushanbe', country: 'TJ'),
];

Future<LocationItem?> showSelectLocationDrawer({
  required BuildContext context,
  required String title,
  String? currentId,
}) {
  return showModalBottomSheet<LocationItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => _SelectLocationSheet(title: title, currentId: currentId),
  );
}

class _SelectLocationSheet extends StatefulWidget {
  const _SelectLocationSheet({required this.title, required this.currentId});
  final String title;
  final String? currentId;

  @override
  State<_SelectLocationSheet> createState() => _SelectLocationSheetState();
}

class _SelectLocationSheetState extends State<_SelectLocationSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _fakeLocations
        : _fakeLocations
            .where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.country.toLowerCase().contains(q))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scroll) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: c.gray300, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.title, style: t.h3)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Qidirish...',
                    prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('Topilmadi', style: t.body.copyWith(color: c.textMuted)))
                    : ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                        itemBuilder: (_, i) {
                          final loc = filtered[i];
                          final active = loc.id == widget.currentId;
                          return InkWell(
                            onTap: () => Navigator.pop(context, loc),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      loc.country,
                                      style: t.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(loc.title, style: t.bodyLgMedium)),
                                  if (active) Icon(Icons.check_rounded, color: c.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
