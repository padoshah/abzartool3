import 'dart:io';

abstract final class WindowsInstaller {
  static Future<void> verifyAndInstall(File setup) async {
    final setupPath = setup.path.replaceAll("'", "''");
    final appPath = Platform.resolvedExecutable.replaceAll("'", "''");
    final script =
        "\$candidate=Get-AuthenticodeSignature -LiteralPath '$setupPath'; "
        "\$installed=Get-AuthenticodeSignature -LiteralPath '$appPath'; "
        "if(\$candidate.Status -ne 'Valid' -or \$installed.Status -ne 'Valid'){exit 2}; "
        "if(\$candidate.SignerCertificate.Subject -ne \$installed.SignerCertificate.Subject){exit 3}; "
        "Write-Output \$candidate.SignerCertificate.Subject";
    final verify = await Process.run('powershell.exe',
        <String>['-NoProfile', '-NonInteractive', '-Command', script]);
    if (verify.exitCode != 0 || (verify.stdout as String).trim().isEmpty) {
      throw const FileSystemException(
          'The update signature is invalid or has a different publisher.');
    }
    await Process.start(
        setup.path,
        const <String>[
          '/SILENT',
          '/CLOSEAPPLICATIONS',
          '/RESTARTAPPLICATIONS',
          '/NORESTART'
        ],
        mode: ProcessStartMode.detached);
    exit(0);
  }
}
