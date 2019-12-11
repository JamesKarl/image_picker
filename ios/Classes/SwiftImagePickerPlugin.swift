import Flutter
import UIKit
import TZImagePickerController
import CLImagePickerTool

public class SwiftImagePickerPlugin: NSObject, FlutterPlugin {
    
    static var channel:FlutterMethodChannel?;
    var controllers: FlutterViewController?
    var imageCount = 1;
    var type = 0;
    var reSizeRect: CGRect?
    var quarlity: CGFloat = 1;
    var isZip: Bool = false;
    var isCrop: Bool = false;
    var results: FlutterResult?;
    /**
     limitSize 存在时，以limitSize为主, quarlity无效
     */
    var limitSize: CGFloat?;
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_picker", binaryMessenger: registrar.messenger())
    self.channel = channel;
    let instance = SwiftImagePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    lazy var tzImagePicker = { () -> TZImagePickerController in
        let picker = TZImagePickerController(maxImagesCount: 9, delegate: self);
        return picker!;
    }()
    
    lazy var imagePicker = { () -> UIImagePickerController in
        let picker = UIImagePickerController();
        picker.sourceType = UIImagePickerController.SourceType.camera;
        picker.delegate = self;
        return picker;
    }()
    
    let imagePickTool = CLImagePickerTool();

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.results = result;
    let dict:Dictionary<String, Any> = call.arguments as! Dictionary<String, Any>;
    let isCamera:Bool = dict["camera"] as! Bool;
    let windows = UIApplication.shared.delegate?.window as! UIWindow;
              let vc = windows.rootViewController as! FlutterViewController;
              controllers = vc;
    imagePickTool.cameraOut = true
    imagePickTool.isHiddenVideo = true
    if dict["maxSize"] != nil && !(dict["maxSize"] is NSNull) {
        self.imageCount = dict["maxSize"] as! Int;
    }
    if dict["quality"] != nil && !(dict["quality"] is NSNull) {
        self.quarlity = (dict["quality"] as! CGFloat) ;
    }
    if dict["crop"] != nil && !(dict["crop"] is NSNull) {
        self.isCrop = dict["crop"] as! Bool;
    }
    if self.imageCount == 1 && self.isCrop {
        imagePickTool.singleImageChooseType = .singlePictureCrop
    }
    imagePickTool.singleModelImageCanEditor = true
    imagePickTool.cl_setupImagePickerWith(MaxImagesCount: self.imageCount ) { (asset,cutImage) in
        var images = [String]();
        for item in asset {
            let phasset = item as PHAsset;
            let image = self .assetToUIImage(asset: phasset);
            let path = NSHomeDirectory() as NSString;
                    let f = DateFormatter();
                    f.dateFormat = "yyyy-MM-dd-HH:mm:ss";
                    f.timeStyle = .full;
                    let m = f.string(from: Date());
                    let imagePath = path.appendingPathComponent("Documents/image1\(m).png") as NSString;
                    var imageData = image.jpegData(compressionQuality: self.quarlity);
                    do {
                        try imageData?.write(to: URL(fileURLWithPath: imagePath as String))
//                         if self.results != nil {
//                             self.results!([imagePath]);
//                         };
                        images.append(imagePath as String);
                    }
                    catch {
                        print(error);
                    }
        }
        self.results!(images);
        SwiftImagePickerPlugin.channel?.invokeMethod("onFinishPickImage", arguments: images)
        print("返回的asset数组是\(asset)")
    }
    return;
    if !isCamera {
       
           if dict["maxSize"] != nil && !(dict["maxSize"] is NSNull) {
               self.imageCount = dict["maxSize"] as! Int;
               pickImage(controller:vc, count: dict["maxSize"] as! Int);
           }
           else {
               pickImage(controller:vc, count: 9);
           }
           if dict["quality"] != nil && !(dict["quality"] is NSNull) {
               self.quarlity = (dict["quality"] as! CGFloat) ;
           }
           if dict["limitSize"] != nil && !(dict["limitSize"] is NSNull) {
               self.limitSize = CGFloat(dict["limitSize"] as! Int);
           }
           if dict["crop"] != nil && !(dict["crop"] is NSNull) {
               self.isCrop = dict["crop"] as! Bool;
           }
    }
    else {
        let windows = UIApplication.shared.delegate?.window as! UIWindow;
                let vc = windows.rootViewController as! FlutterViewController;
                let dict:Dictionary<String, Any> = call.arguments as! Dictionary<String, Any>;
        //        if dict["count"] != nil && !(dict["count"] is NSNull) {
        //            self.imageCount = dict["count"] as! Int;
        //            pickImage(controller:vc, count: dict["count"] as! Int);
        //        }
        //        else {
        //            pickImage(controller:vc, count: 9);
        //        }
                if dict["quality"] != nil && !(dict["quality"] is NSNull) {
                    self.quarlity = (dict["quality"] as! CGFloat) ;
                }
                if dict["limitSize"] != nil && !(dict["limitSize"] is NSNull) {
                    self.limitSize = CGFloat(dict["limitSize"] as! Int);
                }
                if dict["crop"] != nil && !(dict["crop"] is NSNull) {
                    self.isCrop = dict["crop"] as! Bool;
                }
                self.imagePicker.allowsEditing = self.isCrop;
                controllers = vc;
                vc.present(self.imagePicker, animated: true, completion: nil);
    }
    return;
    print(call.method);
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    break;
    case "getPlatformPickImage":
    print("--- 开始选取图片")
    let windows = UIApplication.shared.delegate?.window as! UIWindow;
    let vc = windows.rootViewController as! FlutterViewController;
    controllers = vc;
    
    if dict["count"] != nil && !(dict["count"] is NSNull) {
        self.imageCount = dict["count"] as! Int;
        pickImage(controller:vc, count: dict["count"] as! Int);
    }
    else {
        pickImage(controller:vc, count: 9);
    }
    if dict["quarlity"] != nil && !(dict["quarlity"] is NSNull) {
        self.quarlity = (dict["quarlity"] as! CGFloat) ;
    }
    if dict["limitSize"] != nil && !(dict["limitSize"] is NSNull) {
        self.limitSize = CGFloat(dict["limitSize"] as! Int);
    }
    if dict["isCrop"] != nil && !(dict["isCrop"] is NSNull) {
        self.isCrop = dict["isCrop"] as! Bool;
    }
    break;
    case "getPlatformTakePhoto":
        let windows = UIApplication.shared.delegate?.window as! UIWindow;
        let vc = windows.rootViewController as! FlutterViewController;
        let dict:Dictionary<String, Any> = call.arguments as! Dictionary<String, Any>;
//        if dict["count"] != nil && !(dict["count"] is NSNull) {
//            self.imageCount = dict["count"] as! Int;
//            pickImage(controller:vc, count: dict["count"] as! Int);
//        }
//        else {
//            pickImage(controller:vc, count: 9);
//        }
        if dict["quarlity"] != nil && !(dict["quarlity"] is NSNull) {
            self.quarlity = (dict["quarlity"] as! CGFloat) ;
        }
        if dict["limitSize"] != nil && !(dict["limitSize"] is NSNull) {
            self.limitSize = CGFloat(dict["limitSize"] as! Int);
        }
        if dict["isCrop"] != nil && !(dict["isCrop"] is NSNull) {
            self.isCrop = dict["isCrop"] as! Bool;
        }
        self.imagePicker.allowsEditing = self.isCrop;
        controllers = vc;
        vc.present(self.imagePicker, animated: true, completion: nil);
        break;
    default:
    result(FlutterMethodNotImplemented);
    }
  }
    
    func pickImage(controller:FlutterViewController, count: Int)  {
        self.tzImagePicker.maxImagesCount = count;
        self.tzImagePicker.allowPickingImage = true;
        self.tzImagePicker.allowTakePicture = false;
        self.tzImagePicker.allowCameraLocation = true;
        self.tzImagePicker.allowTakeVideo = false;
        self.tzImagePicker.showSelectedIndex = true;
        self.tzImagePicker.showSelectBtn = false;
        self.tzImagePicker.allowCrop = self.isCrop;
        self.tzImagePicker.modalPresentationStyle = .fullScreen
        controller.present(self.tzImagePicker, animated: false, completion: nil);
    }
}

extension SwiftImagePickerPlugin:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    // MARK: UIImagePickerControllerDelegate
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            return;
            let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage;
            let path = NSHomeDirectory() as NSString;
            let f = DateFormatter();
            f.dateFormat = "yyyy-MM-dd-HH:mm:ss";
            f.timeStyle = .full;
            let m = f.string(from: Date());
            let imagePath = path.appendingPathComponent("Documents/image1\(m).png") as NSString;
    //        var quarlity:CGFloat = self.quarlity;
    //        var imageData = image.pngData();
    //        if imageData != nil && imageData!.count > 24 * 1024 {
    //            for i in 1...9 {
    //                quarlity =  CGFloat(Float(10 - i) / 10.0);
    //                imageData = image.jpegData(compressionQuality: CGFloat(quarlity))
    //                if imageData!.count <= Int(self.limitSize * 1024) {
    //                    break;
    //                }
    //                print(i);
    //            }
    //            if imageData!.count >  Int(self.limitSize * 1024){
    //                quarlity = 0.05
    //            }
    //            imageData = image.jpegData(compressionQuality: CGFloat(quarlity))
    //        }
            var imageData = image.jpegData(compressionQuality: self.quarlity);
            if self.limitSize != nil {
                let img = compressImageSize(image, toByte: NSInteger(self.limitSize! * 1024));
                imageData = img.jpegData(compressionQuality: 1.0);
            }
            do {
                try imageData?.write(to: URL(fileURLWithPath: imagePath as String))
                 if self.results != nil {
                     self.results!([imagePath]);
                 };
                SwiftImagePickerPlugin.channel?.invokeMethod("onFinishPickImage", arguments: [imagePath])
            }
            catch {
                print(error);
            }
            picker.modalPresentationStyle = .fullScreen
            let vcc:TZPhotoPreviewController = TZPhotoPreviewController();
            vcc.isCropImage = true;
            picker.present(vcc, animated: true, completion: nil);
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            controllers?.dismiss(animated: true, completion: nil);
            SwiftImagePickerPlugin.channel?.invokeMethod("onCanclePickImage", arguments: nil)
        }
}

extension SwiftImagePickerPlugin : TZImagePickerControllerDelegate {
    // MARK: TZImagePickerControllerDelegate
        public func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
            if photos != nil && photos.count != 0 {
                var imagepaths = [String]();
                var count = 0;
                for item in photos {
                    count += 1;
                    let path = NSHomeDirectory() as NSString;
                    let f = DateFormatter();
                    f.dateFormat = "yyyy-MM-dd-HH:mm:ss";
                    f.timeStyle = .full;
                    let m = f.string(from: Date());
                    let imagePath = path.appendingPathComponent("Documents/image1\(m)\(count).png") as NSString;
    //                var quarlity:CGFloat = self.quarlity;
    //                var imageData = item.jpegData(compressionQuality: CGFloat(quarlity));
    //                if imageData != nil && imageData!.count > Int(self.limitSize * 1024) {
    //                    for i in 1...9 {
    //                        quarlity =  CGFloat(Float(10 - i) / 10.0);
    //                        imageData = item.jpegData(compressionQuality: CGFloat(quarlity))
    //                        if imageData!.count <= Int(self.limitSize * 1024) {
    //                            break;
    //                        }
    //                        print(i);
    //                    }
    //                    if imageData!.count >  Int(self.limitSize * 1024){
    //                        quarlity = 0.05
    //                    }
    //                    imageData = item.jpegData(compressionQuality: CGFloat(quarlity))
    //                }
                    var imageData = item.jpegData(compressionQuality: self.quarlity);
                    if self.limitSize != nil {
                        let img = compressImageSize(item, toByte: NSInteger(self.limitSize! * 1024));
                        imageData = img.jpegData(compressionQuality: 1.0);
                    }
                    do {
                        try imageData?.write(to: URL(fileURLWithPath: imagePath as String))
                        imagepaths.append(imagePath as String);
                        print(imagepaths);
                    }
                    catch {
                        print(error);
                    }
                }
                if self.results != nil {
                    self.results!(imagepaths);
                }; SwiftImagePickerPlugin.channel?.invokeMethod("onFinishPickImage", arguments: imagepaths)
            }
        }
       
        public func tz_imagePickerControllerDidCancel(_ picker: TZImagePickerController!) {
            SwiftImagePickerPlugin.channel?.invokeMethod("onCanclePickImage", arguments: nil)
        }
}

extension SwiftImagePickerPlugin {
    // MARK: - 将UIImage对象压缩成指定大小
    func compressImageSize(_ image: UIImage, toByte: NSInteger) -> UIImage {
        var compress:CGFloat = 1;
        var data:NSData = image.jpegData(compressionQuality: compress)! as NSData;
        if data.length < toByte {
            return image;
        }
        
        var max:CGFloat = 1;
        var min:CGFloat = 0;
        for _ in 0...6 {
            compress = (max + min)/2.0;
            data = image.jpegData(compressionQuality: compress)! as NSData;
            if data.length > toByte {
                max = compress;
            }
            else if data.length < Int(Float(toByte) * 0.9) {
                min = compress;
            }
            else {
                break;
            }
        }
        
        var resultImage = UIImage.init(data: data as Data)!;
        if data.length <= toByte {
            return resultImage;
        }
        
        var lastDataLength = 0;
        while data.length > toByte && data.length != lastDataLength {
            lastDataLength = data.length;
            let ratio = CGFloat(toByte/data.length);
            let size = CGSize(width: resultImage.size.width * sqrt(ratio), height: resultImage.size.height * sqrt(ratio));
            
            UIGraphicsBeginImageContext(size);
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext()!;
            UIGraphicsEndImageContext()
            data = resultImage.jpegData(compressionQuality: compress) as! NSData;
        }
        return resultImage;
    }
    
    // MARK: - 将PHAsset对象转为UIImage对象
    func assetToUIImage(asset: PHAsset) -> UIImage {
        var image = UIImage()
        
        // 新建一个默认类型的图像管理器imageManager
        let imageManager = PHImageManager.default()
        
        // 新建一个PHImageRequestOptions对象
        let imageRequestOption = PHImageRequestOptions()
        
        // PHImageRequestOptions是否有效
        imageRequestOption.isSynchronous = true
        
        // 缩略图的压缩模式设置为无
        imageRequestOption.resizeMode = .none
        
        // 缩略图的质量为高质量，不管加载时间花多少
        imageRequestOption.deliveryMode = .highQualityFormat
        
        // 按照PHImageRequestOptions指定的规则取出图片
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: imageRequestOption, resultHandler: {
            (result, _) -> Void in
            image = result!
        })
        return image
    }
}

enum PhotoType:Int {
    case PhotoMode;
    case CameraMode;
    case AlbumMode
    
    
}

extension PhotoType {
    static func ofIndex(index: Int) -> PhotoType {
        return [PhotoType.AlbumMode, PhotoType.CameraMode, PhotoType.AlbumMode][index];
    }
}
