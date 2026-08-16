import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/models/file_entry.dart';
import '../../core/native/native_operations.dart';
import '../../core/services/file_service.dart';
import '../../shared/widgets/feature_scaffold.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final password = TextEditingController();
  final ownerPassword = TextEditingController();
  FileEntry? input;
  bool printAllowed = true,
      copyAllowed = true,
      modifyAllowed = true,
      annotateAllowed = true,
      obscure = true,
      running = false;
  Object? error;

  Future<void> pick() async {
    final files = await FileService().pickFiles(multiple: false);
    if (files.isNotEmpty)
      setState(() {
        input = files.first;
        error = null;
      });
  }

  Future<void> encrypt() async {
    final file = input;
    if (file == null || password.text.isEmpty) return;
    final pdf = file.extension == 'pdf';
    final output = await FilePicker.platform.saveFile(
        fileName: pdf ? 'protected.pdf' : '${file.name}.abze',
        type: FileType.any);
    if (output == null) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      if (pdf) {
        await NativeOperations.protectPdf(
            inputPath: file.path,
            outputPath: output,
            userPassword: password.text,
            ownerPassword:
                ownerPassword.text.isEmpty ? password.text : ownerPassword.text,
            allowPrint: printAllowed,
            allowCopy: copyAllowed,
            allowModify: modifyAllowed,
            allowAnnotate: annotateAllowed);
      } else {
        await NativeOperations.encrypt(file.path, output, password.text);
      }
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      password.clear();
      ownerPassword.clear();
      if (mounted) setState(() => running = false);
    }
  }

  Future<void> decrypt() async {
    final file = input;
    if (file == null || password.text.isEmpty) return;
    final pdf = file.extension == 'pdf';
    final output = await FilePicker.platform.saveFile(
        fileName: pdf ? 'unprotected.pdf' : 'decrypted-file',
        type: FileType.any);
    if (output == null) return;
    setState(() {
      running = true;
      error = null;
    });
    try {
      if (pdf) {
        await NativeOperations.unprotectPdf(file.path, output, password.text);
      } else {
        await NativeOperations.decrypt(file.path, output, password.text);
      }
    } catch (value) {
      if (mounted) setState(() => error = value);
    } finally {
      password.clear();
      ownerPassword.clear();
      if (mounted) setState(() => running = false);
    }
  }

  @override
  void dispose() {
    password.dispose();
    ownerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeatureScaffold(
      title: l10n.security,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          FilledButton.icon(
              onPressed: running ? null : pick,
              icon: const Icon(Icons.file_open),
              label: Text(l10n.selectFiles)),
          if (input != null) ListTile(title: Text(input!.name)),
          const SizedBox(height: 20),
          TextField(
              controller: password,
              obscureText: obscure,
              decoration: InputDecoration(
                  labelText: l10n.password,
                  suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure)))),
          const SizedBox(height: 12),
          TextField(
              controller: ownerPassword,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.ownerPassword)),
          const SizedBox(height: 16),
          Text(l10n.permissions,
              style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
              value: printAllowed,
              title: Text(l10n.pages),
              onChanged: (value) =>
                  setState(() => printAllowed = value ?? false)),
          CheckboxListTile(
              value: copyAllowed,
              title: Text(l10n.copyAll),
              onChanged: (value) =>
                  setState(() => copyAllowed = value ?? false)),
          CheckboxListTile(
              value: modifyAllowed,
              title: Text(l10n.replace),
              onChanged: (value) =>
                  setState(() => modifyAllowed = value ?? false)),
          CheckboxListTile(
              value: annotateAllowed,
              title: Text(l10n.annotate),
              onChanged: (value) =>
                  setState(() => annotateAllowed = value ?? false)),
          if (running) const LinearProgressIndicator(),
          if (error != null)
            Text(error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: input == null || running ? null : encrypt,
              child: Text(l10n.addPassword)),
          TextButton(
              onPressed: input == null || running ? null : decrypt,
              child: Text(l10n.removePassword)),
          Text(l10n.neverStored, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
