import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../shared/widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final features = <({IconData icon, String title, String route})>[
      (icon: Icons.swap_horiz, title: l10n.convert, route: '/convert'),
      (icon: Icons.compress, title: l10n.compress, route: '/compress'),
      (icon: Icons.call_merge, title: l10n.merge, route: '/merge'),
      (icon: Icons.call_split, title: l10n.split, route: '/split'),
      (icon: Icons.document_scanner, title: l10n.scan, route: '/scan'),
      (icon: Icons.draw, title: l10n.esign, route: '/esign'),
      (
        icon: Icons.text_snippet_outlined,
        title: l10n.extractText,
        route: '/extract'
      ),
      (
        icon: Icons.picture_as_pdf_outlined,
        title: l10n.pdfTools,
        route: '/pdf-tools'
      ),
    ];
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(title: Text(l10n.appName), actions: <Widget>[
          IconButton(
              tooltip: l10n.openFile,
              onPressed: () => context.push('/viewer/txt'),
              icon: const Icon(Icons.folder_open))
        ]),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(
            children: <Widget>[
              Text(l10n.offlinePitch,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width > 1000 ? 4 : 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final item = features[index];
                  return FeatureCard(
                      icon: item.icon,
                      title: item.title,
                      subtitle: l10n.featureWorkspace,
                      onTap: () => context.push(item.route));
                },
              ),
              const SizedBox(height: 28),
              Text(l10n.recentFiles,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.history),
                            const SizedBox(width: 12),
                            Text(l10n.noJobs)
                          ]))),
            ],
          ),
        ),
      ],
    );
  }
}
