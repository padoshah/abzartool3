import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../shared/widgets/feature_card.dart';
import '../../shared/widgets/feature_scaffold.dart';

class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tools = <({IconData icon, String title, String route})>[
      (icon: Icons.add, title: l10n.insert, route: '/viewer/pdf'),
      (icon: Icons.delete_outline, title: l10n.delete, route: '/split'),
      (icon: Icons.rotate_right, title: l10n.rotate, route: '/viewer/pdf'),
      (icon: Icons.crop, title: l10n.crop, route: '/viewer/pdf'),
      (icon: Icons.copy, title: l10n.duplicate, route: '/merge'),
      (icon: Icons.reorder, title: l10n.pages, route: '/split'),
      (icon: Icons.image_outlined, title: l10n.imageViewer, route: '/viewer/image'),
      (icon: Icons.text_fields, title: l10n.pdfObjectEditor, route: '/pdf-objects'),
      (icon: Icons.branding_watermark, title: l10n.watermark, route: '/annotate'),
      (icon: Icons.numbers, title: l10n.pages, route: '/annotate'),
      (icon: Icons.account_tree, title: l10n.pdfStructureEditor, route: '/pdf-structure'),
      (icon: Icons.healing, title: l10n.repairPdf, route: '/pdf-repair'),
      (icon: Icons.compress, title: l10n.compress, route: '/compress'),
      (icon: Icons.draw, title: l10n.annotate, route: '/annotate'),
      (icon: Icons.security, title: l10n.security, route: '/security'),
    ];
    return FeatureScaffold(
      title: l10n.pdfTools,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 4 : 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
        itemCount: tools.length,
        itemBuilder: (context, index) => FeatureCard(icon: tools[index].icon, title: tools[index].title, onTap: () => context.push(tools[index].route)),
      ),
    );
  }
}
