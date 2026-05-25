import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuestLoadsScreen extends StatefulWidget {
  const GuestLoadsScreen({super.key});

  @override
  State<GuestLoadsScreen> createState() => _GuestLoadsScreenState();
}

class _GuestLoadsScreenState extends State<GuestLoadsScreen> {
  int _tab = 0;
  int _bottom = 0;

  static const _cards = [
    _GuestCardData(
      title: 'ExportView LTD',
      rating: '4.5',
      price: '20 000 000 uzs',
      from: 'Samarkand, Uz.',
      to: 'Astana, Kz.',
      date1: 'Mon 06/25',
      date2: 'Mon 06/25',
      chips: ['Driver', 'Flatbed', 'DH: 20 km', '100 m3', 'Full', '334 km'],
    ),
    _GuestCardData(
      title: 'Mercedes AMG4...',
      rating: '4.5',
      price: '30 500 000 uzs',
      from: 'Samarkand, Uz.',
      to: 'Astana, Kz.',
      date1: 'Mon 06/25',
      date2: 'Sun 06/25',
      chips: ['Flatbed', '100 m3', '334 km', 'Full'],
    ),
    _GuestCardData(
      title: 'Volvo FH',
      rating: '4.5',
      price: 'USD 12 000',
      from: 'Samarkand, Uz.',
      to: 'Astana, Kz.',
      date1: 'Mon 06/25',
      date2: 'Sun 06/25',
      chips: ['Flatbed', '100 m3', '334 km', 'Full', 'DH 50km'],
    ),
    _GuestCardData(
      title: 'Mercedes AMG430',
      rating: '4.5',
      price: 'USD 5 400',
      from: 'Samarkand, Uz.',
      to: 'Astana, Kz.',
      date1: 'Mon 06/25',
      date2: 'Sun 06/25',
      chips: ['Flatbed', '100 m3', '334 km', 'Full'],
    ),
  ];

  void _requireLogin() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Login required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Bu amalni bajarish uchun avval tizimga kiring.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF89AEEF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/auth/welcome');
                  },
                  child: const Text('Kirish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF0057FF)),
                      const SizedBox(width: 8),
                      const Text('LoadMe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(onPressed: _requireLogin, icon: const Icon(Icons.notifications_none, size: 24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        _TopTab(label: 'Trucks', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                        _TopTab(label: 'Loads', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text('Vsego gruzov: 3 200', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                        Spacer(),
                        Icon(Icons.refresh, color: Color(0xFF667085), size: 22),
                      ],
                    ),
                  ),
                  ..._cards.map((e) => GestureDetector(onTap: _requireLogin, child: _GuestCard(data: e))),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottom,
        height: 68,
        onDestinationSelected: (i) {
          setState(() => _bottom = i);
          if (i != 0) _requireLogin();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Post Loads'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'My Loads'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? const Color(0xFFF8F8FA) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.data});

  final _GuestCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${data.title} ${data.rating}*', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
              Text(data.price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0057FF))),
            ],
          ),
          const SizedBox(height: 8),
          _DotLine(text: data.from, date: data.date1, solid: true),
          const SizedBox(height: 4),
          _DotLine(text: data.to, date: data.date2, solid: false),
          const Divider(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.chips
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE9ECF2), borderRadius: BorderRadius.circular(8)),
                      child: Text(e, style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DotLine extends StatelessWidget {
  const _DotLine({required this.text, required this.date, required this.solid});

  final String text;
  final String date;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(solid ? Icons.circle : Icons.circle_outlined, size: 8, color: const Color(0xFF0057FF)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
        Text(date, style: const TextStyle(fontSize: 14, color: Color(0xFF98A2B3))),
      ],
    );
  }
}

class _GuestCardData {
  const _GuestCardData({
    required this.title,
    required this.rating,
    required this.price,
    required this.from,
    required this.to,
    required this.date1,
    required this.date2,
    required this.chips,
  });

  final String title;
  final String rating;
  final String price;
  final String from;
  final String to;
  final String date1;
  final String date2;
  final List<String> chips;
}
