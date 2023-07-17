//
//  ImageCacheStorage.swift
//  Ulry
//
//  Created by Matt on 10/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit
import LinksMetadata

extension Notification.Name {
    static let DidUpdateImage = Notification.Name("DidUpdateImage")
}

public class ImageStorage: CacheStorage, Logging {
    public static var shared = ImageStorage()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 1024*1024*3
        cache.evictsObjectsWithDiscardedContent = true
        return cache
    }()

    let imageFolder: URL = {
        let imageFolderURL = Paths.dataFolder.appendingPathComponent("images")
        return imageFolderURL
    }()

    public func storeImageData(_ data: Data, with id: UUID) {
        if !FileManager.default.fileExists(atPath: self.imageFolder.path) {
            do {
                try FileManager.default.createDirectory(atPath: imageFolder.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("Cannot create image folder: \(error)")
                return
            }
        }

        let fileURL = imageFolder.appendingPathComponent(id.uuidString).appendingPathExtension("jpeg")

        do {
            try data.write(to: fileURL)
            NotificationCenter.default.post(name: .DidUpdateImage, object: nil, userInfo: ["imageId": id.uuidString])
        } catch {
            logger.error("Cannot save image: \(error)")
            return
        }
    }

    public func deleteImageData(for link: Link) throws {
        let path = imageFolder.appendingPathComponent(link.id.uuidString).appendingPathExtension("jpeg")
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }
    }

    public func deleteImageData(with id: UUID) throws {
        let path = imageFolder.appendingPathComponent(id.uuidString).appendingPathExtension("jpeg")
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }
    }

    public func storeImageData(_ data: Data, for link: Link) {
        if !FileManager.default.fileExists(atPath: self.imageFolder.path) {
            do {
                try FileManager.default.createDirectory(atPath: imageFolder.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("Cannot create image folder: \(error)")
                return
            }
        }

        let fileURL = imageFolder.appendingPathComponent(link.id.uuidString).appendingPathExtension("jpeg")

        do {
            try data.write(to: fileURL)
            NotificationCenter.default.post(name: .DidUpdateImage, object: nil, userInfo: ["imageId": link.id.uuidString])
        } catch {
            logger.error("Cannot save image: \(error)")
            return
        }
    }

    public func storeImageData(_ data: Data, filenameId: String) {
        if !FileManager.default.fileExists(atPath: self.imageFolder.path) {
            do {
                try FileManager.default.createDirectory(atPath: imageFolder.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("Cannot create image folder: \(error)")
                return
            }
        }

        let fileURL = imageFolder.appendingPathComponent(filenameId).appendingPathExtension("jpeg")

        do {
            try data.write(to: fileURL)
            NotificationCenter.default.post(name: .DidUpdateImage, object: nil, userInfo: ["imageId": filenameId])
        } catch {
            logger.error("Cannot save image: \(error)")
            return
        }
    }

    /// Deletes image for a specific link
    ///
    /// - parameter link: Link of which you want to delete the image
    public func deleteImage(for link: Link) {
        let imageUrl = imageFolder.appendingPathComponent(link.id.uuidString).appendingPathExtension("jpeg")
        if FileManager.default.fileExists(atPath: imageUrl.path) {
            logger.info("deleting image \(link.id.uuidString)")
            try? FileManager.default.removeItem(at: imageUrl)
        }
    }

    /// Retrieves data of image with a specific filename
    ///
    /// - parameter filename: Image filename
    public func getImageData(filename: String) -> Data? {
        let imageUrl = self.imageFolder.appendingPathComponent(filename)
        return try? Data(contentsOf: imageUrl)
    }

    /// Retrieves data of image of a specific link
    ///
    /// - parameter link: Link of which you want to get the image data
    public func getImageData(for link: Link) -> Data? {
        let imageUrl = self.imageFolder.appendingPathComponent(link.id.uuidString).appendingPathExtension("jpeg")
        return try? Data(contentsOf: imageUrl)
    }

    /// Retrieves image of a specific link
    ///
    /// - parameter link: Link of which you want to get the image data
    public func getImage(for link: Link) -> UIImage? {
        if let img = cache.object(forKey: link.id.uuidString as NSString) {
            return img
        }

        guard let data = getImageData(for: link) else { return nil }
        guard let img = UIImage(data: data) else { return nil }

        Task {
            if let preparedImage = await img.byPreparingForDisplay() {
                cache.setObject(preparedImage, forKey: link.id.uuidString as NSString)
            }
        }
        
        return img
    }

    /// Loads image in cache using the new API `prepareForDisplay`
    ///
    /// According to [stackoverflow](https://stackoverflow.com/a/10664707/3795691)
    /// UIImage is lazy loaded only when it is actually shown for the first time on screen.
    ///
    /// This method was discusses in this [talk](https://www.youtube.com/watch?v=Vbpr9xp7XKk&list=PLED4k3CZkY9RBYTMNziVhwXGepdcUIz8B&index=7)
    ///
    /// This method forces the image rendering and saves the image in cache so the scrolling
    /// experience is smooth and fast in UITableView
    public func loadImageInCache(for id: String) {
        if let _ = cache.object(forKey: id as NSString) { return }
        let imageUrl = imageFolder.appendingPathComponent(id).appendingPathExtension("jpeg")

        guard let image = UIImage(contentsOfFile: imageUrl.path) else { return }

        Task {
            if let preparedImage = await image.byPreparingForDisplay() {
                cache.setObject(preparedImage, forKey: id as NSString)
            }
        }
    }


    /// Loads image in cache
    ///
    /// According to [stackoverflow](https://stackoverflow.com/a/10664707/3795691)
    /// UIImage is lazy loaded only when it is actually shown for the first time on screen.
    ///
    /// This method forces the image rendering and saves the image in cache so the scrolling
    /// experience is smooth and fast in UITableView
    public func loadImageInCacheWithUIGraphicsContext(for id: String) {
        if let _ = cache.object(forKey: id as NSString) { return }
        DispatchQueue.global().async { [unowned self] in
            let imageUrl = self.imageFolder.appendingPathComponent(id).appendingPathExtension("jpeg")
            guard let image = UIImage(contentsOfFile: imageUrl.path) else { return }
            let imageSize = image.size
            UIGraphicsBeginImageContext(imageSize)
            image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                cache.setObject(image, forKey: id as NSString)
                return
            }
            cache.setObject(renderedImage, forKey: id as NSString)
        }
    }

    public func getTotalImageOccupiedStorage() -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file

        guard let paths = try? FileManager.default.contentsOfDirectory(atPath: imageFolder.path) else { return "N/A" }
        var totSize: Int64 = 0
        for path in paths {
            let fileAttributes = try! FileManager.default.attributesOfItem(atPath: imageFolder.appendingPathComponent(path).path)
            let fileSize = fileAttributes[.size] as! Int64
            totSize += fileSize
        }

        return bcf.string(fromByteCount: totSize)
    }
}

extension ImageStorage: LinkImageProvider {

    public func getImageFileURL(for link: Link) -> URL? {
        let imageUrl = imageFolder.appendingPathComponent(link.id.uuidString).appendingPathExtension("jpeg")
        if FileManager.default.fileExists(atPath: imageUrl.path) {
            return imageUrl
        }
        return nil
    }

}
