import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/utils/bytes.dart';
import 'android_installer.dart';
import 'update_models.dart';
import 'update_service.dart';
import 'windows_installer.dart';

class UpdateBootstrap extends StatefulWidget {
  const UpdateBootstrap({required this.child, super.key});
  final Widget child;
  @override
  State<UpdateBootstrap> createState() => _UpdateBootstrapState();
}

class _UpdateBootstrapState extends State<UpdateBootstrap>
    with WidgetsBindingObserver {
  bool checking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  Future<void> check() async {
    if (checking || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool('updates') ?? true)) return;
    final last = preferences.getInt('lastUpdateCheck') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - last <
        const Duration(hours: 24).inMilliseconds) return;
    checking = true;
    try {
      final release = await UpdateService().check();
      await preferences.setInt(
          'lastUpdateCheck', DateTime.now().millisecondsSinceEpoch);
      if (release != null && mounted) await _showRelease(release);
    } catch (_) {
      // Scheduled checks are deliberately silent when offline or rate-limited.
    } finally {
      checking = false;
    }
  }

  Future<void> _showRelease(AppRelease release) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.updateAvailable),
        content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                  Text(release.version,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(release.notes)
                ]))),
        actions: <Widget>[
          TextButton(
              onPressed: () async {
                await (await SharedPreferences.getInstance())
                    .setString('skippedUpdateVersion', release.version);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(l10n.skipVersion)),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.later)),
          FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/updates');
              },
              child: Text(l10n.updateNow)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});
  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  late Future<AppRelease?> release = UpdateService().check();
  double? progress;

  Future<void> install(AppRelease value) async {
    setState(() => progress = 0);
    try {
      final file = await UpdateService().downloadAndVerify(value, (value) {
        if (mounted) setState(() => progress = value);
      });
      if (Platform.isAndroid) {
        await AndroidInstaller.install(file);
      } else if (Platform.isWindows)
        await WindowsInstaller.verifyAndInstall(file);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).offline)));
    } finally {
      if (mounted) setState(() => progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateChecks)),
      body: FutureBuilder<AppRelease?>(
        future: release,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text(l10n.offline));
          final value = snapshot.data;
          if (value == null) return Center(child: Text(l10n.upToDate));
          final asset = value.assets
              .where((item) => item.name.contains(Platform.isAndroid
                  ? 'android-universal'
                  : 'windows-x64-setup'))
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              Text(l10n.updateAvailable,
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(value.version,
                  style: Theme.of(context).textTheme.titleLarge),
              if (asset != null) Text(formatBytes(asset.size)),
              const SizedBox(height: 16),
              SelectableText(value.notes),
              if (progress != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: LinearProgressIndicator(value: progress)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: progress == null ? () => install(value) : null,
                  child: Text(l10n.updateNow)),
              TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(l10n.later)),
              TextButton(
                  onPressed: () async {
                    await (await SharedPreferences.getInstance())
                        .setString('skippedUpdateVersion', value.version);
                    if (context.mounted) Navigator.maybePop(context);
                  },
                  child: Text(l10n.skipVersion)),
            ],
          );
        },
      ),
    );
  }
}
