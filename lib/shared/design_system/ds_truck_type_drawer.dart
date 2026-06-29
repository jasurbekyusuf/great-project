import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Truck-type taxonomy — Figma "Transport turi" picker component
/// (node 6435:42249). 7 groups, each with its concrete vehicle types.
class TruckTypeGroup {
  const TruckTypeGroup(this.name, this.items);
  final String name;
  final List<String> items;
}

const kTruckTypeGroups = <TruckTypeGroup>[
  TruckTypeGroup('Yopiq transportlar', [
    'Yopiq furgon',
    'Tent / Refer',
    'Isuzu Kichik',
    'Isuzu Katta',
    'Tent / Shtora',
    'Avtopoyezd / Parovoz',
  ]),
  TruckTypeGroup('Harorat saqlovchi', [
    'Refrijerator',
    'Izoterma',
    'Termobudka',
    'Multi-temperatura',
  ]),
  TruckTypeGroup('Kuzovli transportlar', [
    'Isuzu Kichik',
    'Isuzu Katta',
    'Kamaz',
    'Howo / Chacman',
  ]),
  TruckTypeGroup('Yengil yuk transportlari', [
    'Damas',
    'Labo',
    'Gazel',
    'Porter / Bongo',
    'JAC / Bongo / Howo Layt',
  ]),
  TruckTypeGroup('Ochiq bortli', [
    'Bortovoy / Ochiq platforma',
    'Bortovoy / Platforma',
    'Shalanda / Ploshadka',
    'Jambo / Mega',
    'Tral / Nizkoramnik',
    'Tyagach (Fura kallasi)',
    'Konteynerovoz',
  ]),
  TruckTypeGroup('Maxsus texnika & Qurilish', [
    'Samosval',
    'Sementovoz',
    'Zernovoz',
    'Tonar',
    'Lesovoz',
    'Skotovoz',
    'Manipulyator',
    'Evakuator',
    'Avtovoz',
  ]),
  TruckTypeGroup('Sisterna', [
    'Sisterna',
    'Bitumovoz',
    'Molokovoz',
    'Ximik sisterna',
    'Sisterna-konteynerovoz',
  ]),
];

class _Popular {
  const _Popular(this.label, this.icon);
  final String label;
  final IconData icon;
}

// Quick-pick cards. Icons are lucide stand-ins for the Figma custom glyphs.
const _popular = <_Popular>[
  _Popular('Tent', LucideIcons.truck),
  _Popular('Refrijerator', LucideIcons.snowflake),
  _Popular('Isuzu Katta (FVR)', LucideIcons.truck),
  _Popular('Isuzu Kichkina (NQR)', LucideIcons.truck),
];

/// The quick-pick transport labels shown at the top of the loads-search inline
/// transport dropdown (Figma 6435:34680) — the same curated set as the popular
/// cards above. Public so the market search sheet can reuse the exact list.
const kPopularTruckTypes = <String>[
  'Tent',
  'Refrijerator',
  'Isuzu Katta (FVR)',
  'Isuzu Kichkina (NQR)',
];

/// Grouped multi-select truck-type picker (search + popular grid + accordion).
/// Returns the selected type labels, or null if dismissed without saving.
Future<List<String>?> showDsTruckTypeDrawer({
  required BuildContext context,
  required List<String> initialSelected,
}) {
  // Figma "Transport turi" is a full-screen page (node 6435:41514), not a
  // bottom sheet — push it on the root navigator so it renders above the shell
  // and the bottom navigation bar is hidden. Returns the picked labels (null
  // when dismissed without saving).
  return Navigator.of(context, rootNavigator: true).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TruckTypeFilterScreen(initialSelected: initialSelected),
    ),
  );
}

/// Full-page grouped multi-select truck-type picker (Figma 6435:41514):
/// search → "Mashhurlar" 2×2 grid → "Hammasi" accordion → sticky Saqlash bar.
class TruckTypeFilterScreen extends ConsumerStatefulWidget {
  const TruckTypeFilterScreen({super.key, required this.initialSelected});
  final List<String> initialSelected;
  @override
  ConsumerState<TruckTypeFilterScreen> createState() =>
      _TruckTypeFilterScreenState();
}

class _TruckTypeFilterScreenState extends ConsumerState<TruckTypeFilterScreen> {
  late final Set<String> _selected = {...widget.initialSelected};
  final _search = TextEditingController();
  String _query = '';
  final Set<int> _expanded = {0};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String v) => setState(() {
        if (!_selected.remove(v)) _selected.add(v);
      });

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final q = _query.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header — close (X) + title (Figma 6435:41518: X 24, gap 16, fs16/600).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(LucideIcons.x,
                        size: 24, color: FigmaPalette.ink),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'truckType.title'.tr(ref),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w600,
                      color: FigmaPalette.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _searchField(),
                  const SizedBox(height: 12),
                  if (!searching) ...[
                    _popularGrid(),
                    const SizedBox(height: 12),
                  ],
                  if (searching) _searchResults(q) else _accordion(),
                ],
              ),
            ),
            // Pinned white footer (Figma Frame 1711112371) with the primary
            // Saqlash button; SafeArea keeps it clear of the home indicator.
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, -2),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: _SaveButton(
                  label: 'common.save'.tr(ref),
                  onTap: () => Navigator.pop(context, _selected.toList()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF004EEA), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.search, size: 20, color: Color(0xFF131313)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: FigmaPalette.primary,
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 16,
                height: 24 / 16,
                // Even leading centres the glyphs vertically (level with the
                // search icon) instead of letting them ride high.
                leadingDistribution: TextLeadingDistribution.even,
                color: FigmaPalette.ink,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'common.search'.tr(ref),
                hintStyle: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: FigmaPalette.label,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularGrid() {
    Widget row(int a, int b) => Row(
          children: [
            Expanded(child: _PopularCard(item: _popular[a], selected: _selected.contains(_popular[a].label), onTap: () => _toggle(_popular[a].label))),
            const SizedBox(width: 12),
            Expanded(child: _PopularCard(item: _popular[b], selected: _selected.contains(_popular[b].label), onTap: () => _toggle(_popular[b].label))),
          ],
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('truckType.popular'.tr(ref), style: _sectionStyle),
          const SizedBox(height: 12),
          row(0, 1),
          const SizedBox(height: 12),
          row(2, 3),
        ],
      ),
    );
  }

  Widget _accordion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('truckType.all'.tr(ref), style: _sectionStyle),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: FigmaPalette.sheetBg, borderRadius: BorderRadius.circular(12)),
                child: Text('${kTruckTypeGroups.length}',
                    style: const TextStyle(fontSize: 12, height: 15 / 12, fontWeight: FontWeight.w600, color: FigmaPalette.tertiary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FigmaPalette.divider),
            ),
            child: Column(
              children: [
                for (var i = 0; i < kTruckTypeGroups.length; i++)
                  _groupTile(i, last: i == kTruckTypeGroups.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupTile(int i, {required bool last}) {
    final g = kTruckTypeGroups[i];
    final open = _expanded.contains(i);
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => open ? _expanded.remove(i) : _expanded.add(i)),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: (open || !last) ? FigmaPalette.divider : Colors.transparent)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(g.name, style: _itemStyle.copyWith(fontWeight: FontWeight.w500))),
                Icon(open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 20, color: const Color(0xFF98A1B2)),
              ],
            ),
          ),
        ),
        if (open)
          for (var j = 0; j < g.items.length; j++)
            _itemRow(g.items[j], indent: true, last: last && j == g.items.length - 1),
      ],
    );
  }

  Widget _itemRow(String label, {required bool indent, required bool last}) {
    final on = _selected.contains(label);
    return InkWell(
      onTap: () => _toggle(label),
      child: Container(
        height: 48,
        padding: EdgeInsets.fromLTRB(indent ? 40 : 16, 0, 16, 0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: last ? Colors.transparent : FigmaPalette.divider)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: _itemStyle)),
            _CheckBox(on: on),
          ],
        ),
      ),
    );
  }

  Widget _searchResults(String q) {
    final matches = <String>[];
    for (final g in kTruckTypeGroups) {
      for (final it in g.items) {
        if (it.toLowerCase().contains(q) && !matches.contains(it)) matches.add(it);
      }
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: matches.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('common.notFound'.tr(ref), style: _itemStyle),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FigmaPalette.divider),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < matches.length; i++)
                    _itemRow(matches[i], indent: false, last: i == matches.length - 1),
                ],
              ),
            ),
    );
  }
}

const _sectionStyle = TextStyle(
  fontSize: 14,
  height: 17 / 14,
  fontWeight: FontWeight.w600,
  color: FigmaPalette.ink,
);
const _itemStyle = TextStyle(
  fontSize: 14,
  height: 17 / 14,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.ink,
);

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.item, required this.selected, required this.onTap});
  final _Popular item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 93,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FigmaPalette.sheetBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? blue : const Color(0xFFEAECF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? blue : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 24, color: selected ? Colors.white : blue),
                ),
                _CheckBox(on: selected),
              ],
            ),
            const Spacer(),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 17 / 14, fontWeight: FontWeight.w500, color: FigmaPalette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? const Color(0xFFEAF1FF) : const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: on ? FigmaPalette.primary : const Color(0xFF98A1B2)),
      ),
      child: on ? const Icon(LucideIcons.check, size: 14, color: FigmaPalette.primary) : null,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: FigmaPalette.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
