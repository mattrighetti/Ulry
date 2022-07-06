//
//  ImageStorage.swift
//  Ulry
//
//  Created by Mattia Righetti on 7/6/22.
//

import os
import UIKit
import Foundation

class ImageStorage {
    static var shared = ImageStorage()
    
    var imageFolder: URL {
        let appDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageFolderURL = appDirectory.appendingPathComponent("images")
        return imageFolderURL
    }
    
    public func storeImage(_ image: UIImage, filename: String) -> String? {
        if let data = image.jpegData(compressionQuality: 0.9) {
            if !FileManager.default.fileExists(atPath: self.imageFolder.path) {
                do {
                    try FileManager.default.createDirectory(atPath: imageFolder.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    os_log(.error, "Cannot create image folder: %@", error as CVarArg)
                    return nil
                }
            }
            
            let fileURL = imageFolder.appendingPathComponent(filename)
            
            do {
                try data.write(to: fileURL)
                return fileURL.path
            } catch {
                os_log(.error, "Cannot save image: %@", error as CVarArg)
                return nil
            }
        }
        
        return nil
    }
    
    public func getImageData(filename: String) -> Data? {
        let imageUrl = self.imageFolder.appendingPathComponent(filename)
        return try? Data(contentsOf: imageUrl)
    }
}
