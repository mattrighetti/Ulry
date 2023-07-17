//
//  MoveToProtectedContainerTask.swift
//  Ulry
//
//  Created by Matt on 16/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

struct MoveToProtectedContainerTask: StartupTask, Logging {
    var runOnce: Bool = true
    var key: String = "MoveToProtectedContainerTask"

    // MARK: - Current

    private let srcRootFolder: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()

    private var currentDbPath: URL {
        srcRootFolder.appendingPathComponent("ulry").appendingPathExtension("sqlite")
    }

    private var currentImageFolderPath: URL {
        srcRootFolder.appendingPathComponent("images")
    }

    // MARK: - Destination

    private let destRootFolder: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }()

    private var destDbPath: URL {
        destRootFolder.appendingPathComponent("ulry").appendingPathExtension("sqlite")
    }

    private var destImageFolderPath: URL {
        destRootFolder.appendingPathComponent("images")
    }

    // MARK: - Task

    public func execTask() throws {
        logger.debug("app folder is: \(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!)")

        guard FileManager.default.fileExists(atPath: currentDbPath.path) else {
            logger.info("no database in document folder, killing task")
            return
        }
        logger.info("file exists at \(currentDbPath.path), moving operation about to start...")

        try createNewFolder(at: destRootFolder.path)
        try createNewFolder(at: destImageFolderPath.path)

        guard FileManager.default.secureCopyItem(at: currentDbPath, to: destDbPath) else {
            logger.error("cannot copy database, encountered error")
            fatalError()
        }

        guard let imageFiles = try? FileManager.default.contentsOfDirectory(atPath: currentImageFolderPath.path) else {
            logger.info("image folder does not exist, skipping copy of image folder")
            return
        }

        var failed = [String]()
        for imageFile in imageFiles {
            let src = currentImageFolderPath.appendingPathComponent(imageFile)
            let dst = destImageFolderPath.appendingPathComponent(imageFile)
            if !FileManager.default.secureCopyItem(at: src, to: dst) {
                failed.append(imageFile)
            }
        }

        if failed.count > 0 {
            logger.error("\(failed.count) images could not be copied to new destination: \(failed)")
        }
    }

    private func createNewFolder(at path: String) throws {
        if !FileManager.default.fileExists(atPath: path) {
            logger.info("creating application support folder at \(path)")
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false)
        } else {
            logger.debug("folder at \(path) is already present, unless this is a dev device this should not happen")
        }
    }
}
