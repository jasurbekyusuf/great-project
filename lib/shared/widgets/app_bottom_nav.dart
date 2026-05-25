import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Loads'),
        NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Trucks'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onDestinationSelected: (index) {
        if (index == 0) context.go('/loads');
        if (index == 1) context.go('/trucks');
        if (index == 2) context.go('/profile');
      },
    );
  }
}
