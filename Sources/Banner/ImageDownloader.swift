//
//  File.swift
//  
//
//  Created by 周伟克 on 2021/1/2.
//

import UIKit

class ImageDownloader {
    
    let semaphore = DispatchSemaphore(value: 1)
    static let share = ImageDownloader()
    lazy var session: URLSession = {
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 5
        return session
    }()
    
    
    lazy var taskMap = [URL: URLSessionDataTask]()
    lazy var observerMap = [URL: [DownloaderObserver]]()
    private init() {}
    
    func download(_ url: URL, observer: DownloaderObserver) {
        semaphore.wait()
        registerObserver(observer, for: url)
        guard taskMap[url] == nil else {
            semaphore.signal()
            return
        }
        let task = session.dataTask(with: url) { (data, response, error) in
            self.semaphore.wait()
            if error == nil, let data = data, let image = UIImage(data: data) {
                self.notifyObseversForUrl(url, image: image, imgData: data)
            } else {
                self.notifyObseversForUrl(url, image: nil, imgData: nil)
            }
            self.taskMap[url] = nil
            self.removeObserversForURL(url)
            self.semaphore.signal()
        }
        taskMap[url] = task
        semaphore.signal()
        task.resume()
    }
    
    /// 注册下载监听
    func registerObserver(_ observer: DownloaderObserver, for url: URL) {
        var observers = observerMap[url] ?? []
        guard !observers.contains(observer) else {
            return
        }
        observers.append(observer)
        observerMap[url] = observers
    }
    
    /// 移除下载监听
    func removeObserversForURL(_ url: URL) {
        observerMap[url] = nil
    }
    
    func notifyObseversForUrl(_ url: URL, image: UIImage?, imgData: Data?) {
        observerMap[url]?.forEach({ (observer) in
            observer.handler(image, imgData)
        })
    }
}

