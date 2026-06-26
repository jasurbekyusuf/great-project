import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/shared/widgets/frosted_section_header.dart';

/// Figma "Qo'llanmalar" (6971:42093) — a frosted header over a vertical list
/// (gap 8) of guide cards. Each 343×108 white r16 card pairs an 84×84 dark
/// thumbnail (image darkened by a 48% black overlay + a centred white play
/// triangle) with a title / description column.
///
/// Content is placeholder sample data until the guides endpoint is wired.
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  static const _guides = <_Guide>[
    _Guide(
      title: 'Qanday qilib yuk joylash mumkin?',
      description:
          'Yuk joylash jarayoni 0 dan boshlab tushuntiriladi va har bir qadam '
          'batafsil ko‘rsatiladi.',
    ),
    _Guide(
      title: 'Magnit funksiyasidan to‘g‘ri foydalanish',
      description:
          'Ma’lumotlarni to‘g‘ri kiritish va magnit funksiyasidan samarali '
          'foydalanish bo‘yicha qo‘llanma.',
    ),
    _Guide(
      title: 'Qanday qilib yuk joylash mumkin?',
      description:
          'Yuk joylash jarayoni 0 dan boshlab tushuntiriladi va har bir qadam '
          'batafsil ko‘rsatiladi.',
    ),
    _Guide(
      title: 'Magnit funksiyasidan to‘g‘ri foydalanish',
      description:
          'Ma’lumotlarni to‘g‘ri kiritish va magnit funksiyasidan samarali '
          'foydalanish bo‘yicha qo‘llanma.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: Column(
        children: [
          const FrostedSectionHeader(title: 'Qo‘llanmalar'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _guides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _GuideCard(guide: _guides[i], onTap: () {}),
            ),
          ),
        ],
      ),
    );
  }
}

class _Guide {
  const _Guide({required this.title, required this.description});
  final String title;
  final String description;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide, required this.onTap});

  final _Guide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const _GuideThumb(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B1020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF303236),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideThumb extends StatelessWidget {
  const _GuideThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1D2129),
        borderRadius: BorderRadius.circular(12),
      ),
      // TODO: when guide thumbnails are wired, render the cover image here
      // under a #000000 @ 48% overlay (Figma "image 431").
      child: const Icon(LucideIcons.play, size: 24, color: Colors.white),
    );
  }
}
