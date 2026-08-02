/// Shared bottom-navigation shell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    const destinations = ['/learn', '/drill', '/table', '/progress'];
    final selectedIndex = destinations.indexWhere(location.startsWith);

    return Scaffold(
      body: child,
      bottomNavigationBar: location.startsWith('/table')
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) => context.go(destinations[index]),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.route_outlined),
                  selectedIcon: const Icon(Icons.route),
                  label: strings.learnTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.speed_outlined),
                  selectedIcon: const Icon(Icons.speed),
                  label: strings.drillTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.style_outlined),
                  selectedIcon: const Icon(Icons.style),
                  label: strings.tableTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: strings.profileTab,
                ),
              ],
            ),
    );
  }
}
