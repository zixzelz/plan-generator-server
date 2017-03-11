//
//  TemporaryFileCacheManager.swift
//  kitura-helloworld
//
//  Created by Ruslan Maslouski on 3/11/17.
//
//

import Foundation
import LoggerAPI

class TemporaryFileCacheManager {

    private let tempFolder = "/public/temp"

    init() {
        createTempFolderIfNeeded()
    }

    func saveFile(name: String? = nil, data: Data) -> URL? {
        let fileName = name ?? "\(UUID().uuidString)"

        let fileManager = FileManager()
        let pathToTempFolder = tempFolderPath(forFileManager: fileManager)

        let pathToSave = "\(pathToTempFolder)/\(fileName)"

        let url = URL(fileURLWithPath: pathToSave)
        do {
            try data.write(to: url, options: .atomic)
        } catch let error as NSError {
            Log.error("[TemporaryFileCacheManager] ❌ Error savig file: \(error.localizedDescription)")
            return nil
        }

        return url
    }

    fileprivate func createTempFolderIfNeeded() {

        let fileManager = FileManager()
        let pathToTempFolder = tempFolderPath(forFileManager: fileManager)

        if !fileManager.fileExists(atPath: pathToTempFolder) {
            do {
                try fileManager.createDirectory(atPath: pathToTempFolder, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                Log.error("[TemporaryFileCacheManager] ❌ Error creating directory: \(error.localizedDescription)")
            }
        }
    }

    fileprivate func tempFolderPath(forFileManager fileManager: FileManager) -> String {
        let absolutePath = fileManager.currentDirectoryPath
        let pathToTempFolder = "\(absolutePath)\(tempFolder)"
        return pathToTempFolder
    }
}
