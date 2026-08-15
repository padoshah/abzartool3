import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({required this.icon, required this.title, required this.onTap, this.subtitle, super.key});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: title,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      );
}
