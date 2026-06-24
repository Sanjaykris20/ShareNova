package com.sharenova.sharenova_flutter

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sharenova/native"
    private var pendingResult: MethodChannel.Result? = null
    private val FOLDER_PICKER_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    startActivityForResult(intent, FOLDER_PICKER_REQUEST_CODE)
                }
                "requestManageExternalStorage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        if (!Environment.isExternalStorageManager()) {
                            try {
                                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                                intent.addCategory("android.intent.category.DEFAULT")
                                intent.data = Uri.parse(String.format("package:%s", applicationContext.packageName))
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                val intent = Intent()
                                intent.action = Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION
                                startActivity(intent)
                                result.success(true)
                            }
                        } else {
                            result.success(true) // Already granted
                        }
                    } else {
                        result.success(true) // Not needed for below Android 11
                    }
                }
                "checkManageExternalStorage" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(Environment.isExternalStorageManager())
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == FOLDER_PICKER_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null && data.data != null) {
                val uri = data.data!!
                val takeFlags: Int = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                contentResolver.takePersistableUriPermission(uri, takeFlags)
                pendingResult?.success(uri.toString())
            } else {
                pendingResult?.error("CANCELLED", "User cancelled folder picking", null)
            }
            pendingResult = null
        }
    }
}
