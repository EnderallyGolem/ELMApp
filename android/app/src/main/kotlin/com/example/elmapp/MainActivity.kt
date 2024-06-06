package com.example.elmapp

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import com.baseflow.permissionhandler.PermissionHandlerPlugin
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.elmapp/openfile"
    private var fileUri: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        flutterEngine.plugins.add(PermissionHandlerPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getFileContent" -> {
                    val intent = intent
                    if (intent.action == Intent.ACTION_VIEW || intent.action == Intent.ACTION_EDIT) {
                        fileUri = intent.data
                        if (fileUri != null) {
                            val content = readTextFromUri(fileUri!!)
                            result.success(content)
                        } else {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                "saveFileContent" -> {
                    val content = call.argument<String>("content")
                    if (fileUri != null && content != null) {
                        writeTextToUri(fileUri!!, content)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun readTextFromUri(uri: Uri): String {
        val inputStream = contentResolver.openInputStream(uri)
        val reader = BufferedReader(InputStreamReader(inputStream))
        val stringBuilder = StringBuilder()
        reader.forEachLine { line ->
            stringBuilder.append(line).append("\n")
        }
        reader.close()
        return stringBuilder.toString()
    }

    private fun writeTextToUri(uri: Uri, content: String) {
        val outputStream = contentResolver.openOutputStream(uri)
        val writer = OutputStreamWriter(outputStream)
        writer.write(content)
        writer.flush()
        writer.close()
    }
}
