package com.myb.image_picker

import android.os.Handler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.os.Looper

class ImagePickerPlugin(val registrar: Registrar, val delegate: ImagePickerDelegate) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val delegate = ImagePickerDelegate(registrar.activity())
            registrar.addActivityResultListener(delegate)
            registrar.addRequestPermissionsResultListener(delegate)
            val channel = MethodChannel(registrar.messenger(), "image_picker")
            channel.setMethodCallHandler(ImagePickerPlugin(registrar, delegate))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val result = MethodResultWrapper(result)
        when (call.method) {
            "pickImage" -> {
                delegate.handle(call, result)
            }
            else -> result.notImplemented()
        }
    }

    private class MethodResultWrapper internal constructor(private val methodResult: Result) : Result {
        private val handler: Handler = Handler(Looper.getMainLooper())

        override fun success(result: Any?) {
            handler.post { methodResult.success(result) }
        }

        override fun error(
                errorCode: String, errorMessage: String?, errorDetails: Any?) {
            handler.post { methodResult.error(errorCode, errorMessage, errorDetails) }
        }

        override fun notImplemented() {
            handler.post { methodResult.notImplemented() }
        }
    }
}
