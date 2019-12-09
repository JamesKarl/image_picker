package com.myb.image_picker

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.yalantis.ucrop.UCrop
import com.zhihu.matisse.Matisse
import com.zhihu.matisse.MimeType
import com.zhihu.matisse.engine.impl.GlideEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File

/**
 * Created by tangr on 2019-12-05.
 */
class ImagePickerDelegate(val activity: Activity) : PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
    private val PHOTO_REQUEST_MATISSE: Int = 0
    private val PHOTO_REQUEST_CAMERA: Int = 1
    private val PHOTO_REQUEST_ALBUM: Int = 2
    private val cameraPermissions = arrayOf(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    private val albumPermissions = arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)
    private var result: MethodChannel.Result? = null
    private var call: MethodCall? = null
    private var file: File? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        this.call = call
        this.result = result
        val camera = call.argument<Boolean>("camera")
        if (camera == true) {
            cameraPermission()
        } else {
            albumPermission()
        }
    }

    private fun cameraPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            toCamera()
        } else {
            if (checkPermissionAllGranted(cameraPermissions)) {
                toCamera()
            } else {
                requestPermission(true)
            }
        }
    }

    private fun albumPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            toAlbum()
        } else {
            if (checkPermissionAllGranted(cameraPermissions)) {
                toAlbum()
            } else {
                requestPermission(true)
            }
        }
    }

    private fun toCamera() {
        val name = System.currentTimeMillis().toString() + ".jpg"
        file = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), name)
        val intent = Intent()
        intent.action = "android.media.action.IMAGE_CAPTURE"
        val uri = FileProvider.getUriForFile(activity, "com.myb.image_picker.PhotoPicker", file!!)
        intent.putExtra(MediaStore.EXTRA_OUTPUT, uri)
        intent.addCategory("android.intent.category.DEFAULT")
        activity.startActivityForResult(Intent.createChooser(intent, ""), PHOTO_REQUEST_CAMERA)
    }

    private fun toAlbum() {
        val size = call?.argument<Int>("maxSize")
        if (size == 1) {
            singleSelect()
        } else {
            multiSelect()
        }
    }

    private fun singleSelect() {
        val intent = Intent(Intent.ACTION_GET_CONTENT).setType("image/*")
                .addCategory(Intent.CATEGORY_OPENABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            val mimeTypes = arrayOf("image/jpeg", "image/png")
            intent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
        }
        activity.startActivityForResult(Intent.createChooser(intent, "选取图片"), PHOTO_REQUEST_ALBUM)
    }

    private fun multiSelect() {
        Matisse.from(activity)
                .choose(MimeType.ofImage())
                .autoHideToolbarOnSingleTap(true)
                .countable(true)
                .maxSelectable(call?.argument<Int>("maxSize") ?: 1)
                .restrictOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT)
                .thumbnailScale(0.85f)
                .imageEngine(GlideEngine())
                .theme(R.style.Matisse_My)
                .forResult(PHOTO_REQUEST_MATISSE)
    }

    private fun startCrop(uri: Uri) {
        val crop = call?.argument<Boolean>("crop")
        val uCrop = UCrop.of(uri, Uri.fromFile(File(activity.cacheDir, "cropImage_" + System.currentTimeMillis() +
                ".jpg")))
        if (crop == true) {
            uCrop.withAspectRatio(1f, 1f)
        } else {
            uCrop.useSourceImageAspectRatio()
        }
        val options = UCrop.Options()
        options.setCompressionFormat(Bitmap.CompressFormat.JPEG)
        options.setCompressionQuality(60)
        options.withMaxResultSize(2000, 2000)
        options.setHideBottomControls(true)
        options.setFreeStyleCropEnabled(false)
        options.setShowCropGrid(false)
        options.setToolbarColor(Color.parseColor("#003170"))
        options.setStatusBarColor(Color.parseColor("#003170"))
        options.setToolbarWidgetColor(Color.WHITE)
        options.setRootViewBackgroundColor(Color.WHITE)
        if (crop != true) {
            options.setShowCropFrame(false)
            options.setToolbarTitle("预览")
            options.setOnlyPreview(true)
            options.setDimmedLayerColor(Color.TRANSPARENT)
        }
        uCrop.withOptions(options)
        uCrop.start(activity)
    }

    private fun requestPermission(camera: Boolean) {
        if (camera) {
            ActivityCompat.requestPermissions(activity, cameraPermissions, 0)
        } else {
            ActivityCompat.requestPermissions(activity, albumPermissions, 0)
        }
    }

    private fun requestAgain(permissions: Array<String>) {
        AlertDialog.Builder(activity)
                .setPositiveButton("去设置") { dialog, which ->
                    //如果用户点击了不再提示，就跳到设置页，否则直接申请权限
                    if (ifClickNotAskAgain(permissions)) {
                        val intent = Intent()
                        intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        intent.addCategory(Intent.CATEGORY_DEFAULT)
                        intent.data = Uri.parse("package:" + activity.packageName)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                        intent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                        activity.startActivity(intent)
                    } else {
                        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), 0)
                    }
                }
                .setNegativeButton("取消") { dialog, which ->
                    result?.error("0", "未授予权限", null)
                    activity.finish()
                }
                .setCancelable(false)
                .setMessage("拒绝该权限可能导致无法正常使用")
                .show()
    }

    /**
     * 检查是否拥有指定的所有权限
     */
    private fun checkPermissionAllGranted(permissions: Array<String>): Boolean {
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }

    /**
     * 检测用户是否点击了不再弹出权限框
     * @return
     */
    private fun ifClickNotAskAgain(permissions: Array<String>): Boolean {
        for (permission in permissions) {
            if (!ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
                return true
            }
        }
        return false
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == 0) {
            var isAllGranted = true
            for (grant in grantResults) {
                if (grant != PackageManager.PERMISSION_GRANTED) {
                    isAllGranted = false
                    break
                }
            }
            val camera = call?.argument<Boolean>("camera")
            if (isAllGranted) {
                if (camera == true) {
                    toCamera()
                } else {
                    toAlbum()
                }
            } else {
                requestAgain(if (camera == true) cameraPermissions else albumPermissions)
            }
            return true
        }
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK) {
            if (requestCode == PHOTO_REQUEST_MATISSE) {
                if (data != null) {
                    result?.success(Matisse.obtainPathResult(data))
                }
            } else if (requestCode == PHOTO_REQUEST_ALBUM) {
                if (data != null) {
                    startCrop(data.data)
                }
            } else if (requestCode == PHOTO_REQUEST_CAMERA) {
                startCrop(Uri.fromFile(file))
            } else if (requestCode == UCrop.REQUEST_CROP) {
                if (data != null) {
                    result?.success(arrayListOf(Utils().getPath(activity, UCrop.getOutput(data)!!)))
                }
            }
        } else {
            result?.error("0", "未选择", null)
        }
        return true
    }

}