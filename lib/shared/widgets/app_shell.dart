import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../features/convert/convert_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});
  final String location;
  final Widget child;

  int get selected => switch (location) {
        '/convert' => 1,
        '/toolbox' => 2,
        '/history' => 3,
        '/settings' => 4,
        _ => 0
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget acceptDrops(Widget value) => DropTarget(
          onDragDone: (details) async {
            await ref.read(convertControllerProvider.notifier).addDroppedFiles(
                details.files.map((file) => file.path).toList(growable: false));
            if (context.mounted) context.go('/convert');
          },
          child: value,
        );

    final l10n = AppLocalizations.of(context);
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.home_outlined, label: l10n.home, route: '/'),
      (icon: Icons.swap_horiz, label: l10n.convert, route: '/convert'),
      (icon: Icons.handyman_outlined, label: l10n.toolbox, route: '/toolbox'),
      (icon: Icons.history, label: l10n.history, route: '/history'),
      (icon: Icons.settings_outlined, label: l10n.settings, route: '/settings'),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 800;
    if (wide) {
      return acceptDrops(
        Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: selected,
                onDestinationSelected: (index) =>
                    context.go(items[index].route),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/icons/abzarfile_icon.png',
                        width: 48, height: 48)),
                destinations: items
                    .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon), label: Text(item.label)))
                    .toList(growable: false),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: SafeArea(child: child)),
            ],
          ),
        ),
      );
    }
    return acceptDrops(
      Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (index) => context.go(items[index].route),
          destinations: items
              .map((item) => NavigationDestination(
                  icon: Icon(item.icon), label: item.label))
              .toList(growable: false),
        ),
      ),
    );
  }
}
