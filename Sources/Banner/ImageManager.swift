//
//  File.swift
//  
//
//  Created by 周伟克 on 2021/1/2.
//

import UIKit

/**
 * 图片的获取路径：内存缓存 -> 磁盘缓存  -> 网络请求
 *
 * 如果发生内存警告，简单处理移除内存缓存的所有图片；网络请求之前确认该URL地址是否正在请求。
 *
 * 磁盘缓存&网络请求的回调都是在子线程中完成，所以要注意加锁，保证多线程下数据安全
 */

typealias onGetImage = (UIImage?) -> ()
typealias onDownloadImage = (UIImage?, Data?) -> ()

class ImageManager {
    static let `default` = ImageManager()
    private init() {}
    
    func keyForUrl(_ url: URL) -> String {
        url.absoluteString.md5
    }
}

var identifierObjcKey = 0

extension UIImageView {
    var identifier: String? {
        set {
            objc_setAssociatedObject(self, &identifierObjcKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        get {
            return objc_getAssociatedObject(self, &identifierObjcKey) as? String
        }
    }
    
    func setImage(_ url: URL?, placeHolder: UIImage?) {
        assert(Thread.current.isMainThread)
        if image == nil {
            image = placeHolder
        }
        guard let url = url else {
            return
        }
        identifier = ImageManager.default.keyForUrl(url)
        ImageCacher.share.getImageForKey(identifier!) { (image) in
            guard self.identifier == ImageManager.default.keyForUrl(url) else {
                return
            }
            if let image = image {
                self.setImageInMainThread(image)
            } else {
                ImageDownloader.share.download(url, observer: .init(identifier: self.hashValue, handler: { (img, imgData) in
                    let identifierForImage = ImageManager.default.keyForUrl(url)
                    if let img = img, let imgData = imgData, self.identifier == identifierForImage {
                        self.setImageInMainThread(img)
                        ImageCacher.share.cacheImgData(imgData, for: identifierForImage)
                    }
                }))
            }
        }
        
    }
    
    func setImageInMainThread(_ image: UIImage) {
        DispatchQueue.main.async {
            self.image = image
        }
    }
}

