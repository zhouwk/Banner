//
//  File.swift
//  
//
//  Created by 周伟克 on 2021/1/2.
//

import UIKit

class ImageCacher {
    
    static let share = ImageCacher()
    let fm = FileManager.default
    let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/com.zhouwk.banners/"
    var imgMap = [String: Data]()
    
    var semaphore = DispatchSemaphore(value: 1)
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivememoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    func getImageForKey(_ key: String, result: @escaping onGetImage) {
        // 取出图片
        semaphore.wait()
        if let data = imgMap[key], let image = UIImage(data: data) {
            result(image)
            semaphore.signal()
            return
        }
        semaphore.signal()
        
        DispatchQueue.global().async {
            let path = self.cachePath + key
            let image = UIImage(contentsOfFile: path)
            result(image)
        }
    }
    
    func cacheImgData(_ data: Data, for key: String) {
        semaphore.wait()
        imgMap[key] = data
        semaphore.signal()

        DispatchQueue.global().async {
            // cachePath是.cachesDirectory的子目录，可能会被清理掉(比如APP有清理垃圾功能)，所以不放在单利的init方法中创建
            var isDir: ObjCBool = false
            let _ = self.fm.fileExists(atPath: self.cachePath, isDirectory: &isDir)
            if !isDir.boolValue {
                try? self.fm.createDirectory(atPath: self.cachePath, withIntermediateDirectories: true, attributes: nil)
            }
            let path = self.cachePath + key
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
    
    
    @objc func didReceivememoryWarning(_ notification: Notification) {
        semaphore.wait()
        imgMap.removeAll()
        semaphore.signal()
    }
}

