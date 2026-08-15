package com.padoshah.abzarfile

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val installerChannelName = "com.padoshah.abzarfile/installer"
    private val openChannelName = "com.padoshah.abzarfile/open_file"
    private var openChannel: MethodChannel? = null
    private var pendingOpenPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingOpenPath = materializeIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val path = materializeIntent(intent)
        if (path != null) {
            val channel = openChannel
            if (channel != null) channel.invokeMethod("openFile", path) else pendingOpenPath = path
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        openChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, openChannelName).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "initialFile") {
                    result.success(pendingOpenPath)
                    pendingOpenPath = null
                } else result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installerChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) { result.error("ARGUMENT", "Missing APK path", null); return@setMethodCallHandler }
                    if (!packageManager.canRequestPackageInstalls()) {
                        startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                        result.error("PERMISSION", "Install permission is required", null)
                        return@setMethodCallHandler
                    }
                    val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
                    val install = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(install)
                    result.success(null)
                }
                "openInstallSettings" -> {
                    startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun materializeIntent(source: Intent?): String? {
        if (source?.action != Intent.ACTION_VIEW) return null
        val uri = source.data ?: return null
        if (uri.scheme == "file") return uri.path
        if (uri.scheme != "content") return null
        val displayName = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        } ?: "opened-document"
        val safeName = displayName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val destination = File(cacheDir, "opened/${System.currentTimeMillis()}-$safeName")
        destination.parentFile?.mkdirs()
        contentResolver.openInputStream(uri)?.use { input -> destination.outputStream().use { output -> input.copyTo(output) } } ?: return null
        return destination.absolutePath
    }
}
