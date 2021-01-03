//
//  File.swift
//  
//
//  Created by 周伟克 on 2021/1/2.
//

struct DownloaderObserver: Hashable {
        
    let identifier: Int
    let handler: onDownloadImage
    
    var hashValue: Int {
        identifier
    }
    
    static func == (lhs: DownloaderObserver, rhs: DownloaderObserver) -> Bool {
        lhs.identifier == rhs.identifier
    }

}

