//
//  AppsController.swift
//  kitura-helloworld
//
//  Created by Ruslan Maslouski on 3/11/17.
//
//

import Foundation
import LoggerAPI
import BluemixObjectStorage
import Configuration
import SwiftyJSON

enum AppsControllerError: Error {
    case retrieveContainerError(Error)
    case storeObjectError(Error)
    case fetchObjectError(Error)
    case setNewVersion
    case getLatestVersion
    case sendNotification
    case createManifest(Error?)

    case storeData(Error)
    case dbMgr
    case noDatabase
    case internalError
}

extension AppsControllerError {

    var description: String {
        switch self {
        case .retrieveContainerError(let error):
            return "retrieveContainerError: \(error.localizedDescription)"
        case .storeObjectError(let error):
            return "storeObjectError: \(error.localizedDescription)"
        case .fetchObjectError(let error):
            return "fetchObjectError: \(error.localizedDescription)"
        case .setNewVersion:
            return "setNewVersion error"
        case .sendNotification:
            return "sendNotification error"
        case .createManifest:
            return "createManifest error"
        case .storeData:
            return "storeData error"
        default:
            return "some error"
        }
    }
}

typealias AppsControllerCompletionHandlet = (MainResult<Void, AppsControllerError>) -> Void
typealias GetAppVersionControllerCompletionHandlet = (MainResult<[String: String], AppsControllerError>) -> Void
typealias GetAppControllerCompletionHandlet = (MainResult<Data, AppsControllerError>) -> Void

typealias StoreValueCH = (MainResult<String, AppsControllerError>) -> Void
typealias GetValueCH = (MainResult<[String: String], AppsControllerError>) -> Void

class AppsController {

    private let objstorage: ObjectStorage?
    private var storageContainer: String

    private let appsDatabaseManager: AppsDatabaseManager
    private let notificationManager: NotificationManager

    private var BuildManifest: String
    private var BuildUrl: String

    init(configMgr: ConfigurationManager) {

        notificationManager = NotificationManager(configMgr: configMgr)
        appsDatabaseManager = AppsDatabaseManager(configMgr: configMgr)

        storageContainer = configMgr.isDev ? "apps-dev" : "apps"
        BuildManifest = configMgr.url + "/api/apps"
        BuildUrl = configMgr.url + "/api/storage"

        objstorage = ObjectStorage(projectId: "07224055156344ee867c3f76ffd6248b")
        objstorage?.connect( userId: "bd3219d790b84a3a81e64def37cac42b",
                            password: "tZ7yE&J9IFPlh-y]",
                            region: ObjectStorage.REGION_DALLAS) { (error) in

            if let error = error {
                Log.error("[AppsController] ❌ connect to ObjectStorage error: \(error)")
            } else {
                Log.info("[AppsController] ✅ connect to ObjectStorage success")
            }
        }

    }

    func add(app: Data, version: String, completion: @escaping AppsControllerCompletionHandlet) {

        Make.next { (done) in
            self.appsDatabaseManager.addAppVersion(version: version, completion: done)
        }.handleError { _ in
            completion(.failure(.setNewVersion))
        }.next { (id, done: @escaping AppsControllerCompletionHandlet) in
            self.storeApp(app, name: id, completion: done)
        }.handleError { error in
            completion(.failure(error))
        }.next { (result, done: @escaping NotificationManagerCompletionHandlet) in
            self.notificationManager.send(type: .notify(version: version), completion: done)
        }.handleError { error in
            completion(.failure(.sendNotification))
        }.completed { (result) in
            completion(.success())
        }
    }

    func getLatestVersion(appId: String = "", completion: @escaping GetAppVersionControllerCompletionHandlet) {

        appsDatabaseManager.getLatestAppVersion() { (result) in

            guard case .success(let dict) = result, let id = dict["id"], let version = dict["version"] else {
                completion(.failure(.getLatestVersion))
                return
            }

            let url = self.BuildManifest + "/" + id
            let res = ["version": version, "url": url]

            completion(.success(res))
        }
    }

    func manifest(appId: String, completion: @escaping GetAppControllerCompletionHandlet) {

        appsDatabaseManager.getApp(appId: appId) { (result) in

            guard case .success(let dict) = result, let version = dict["version"] else {
                completion(.failure(.createManifest(nil)))
                return
            }

            let url = self.BuildUrl + "/" + appId

            do {
                let data = try self.createManifest(url: url, bundleId: "com.grsu.PlanGenerator", version: version, title: "PlanGenerator")
                completion(.success(data))
            }
            catch {
                completion(.failure(.createManifest(error)))
            }
        }
    }

    private func createManifest(url: String, bundleId: String, version: String, title: String) throws -> Data {

        let asset = [
            "kind": "software-package",
            "url": url,
        ]

        let metadata = [
            "bundle-identifier": bundleId,
            "bundle-version": version,
            "kind": "software",
            "title": title,
        ]
        let items: [String: Any] = ["assets": [asset], "metadata": metadata]
        let dict: [String: Any] = ["items": [items]]

        let nsDict: AnyObject = NSDictionary(dictionary: dict)

        let data = try PropertyListSerialization.data(fromPropertyList: nsDict, format: PropertyListSerialization.PropertyListFormat.xml, options: 0)
        return data
    }

    // Think about redirect
    func app(appId: String, completion: @escaping GetAppControllerCompletionHandlet) {

        objstorage?.retrieveContainer(name: storageContainer) { (error, container) in

            guard let container = container else {
                Log.error("[AppsController] ❌ retrieveContainer error :: \(error)")

                let error: Error = error ?? AppsController.defaultError()
                completion(.failure(.retrieveContainerError(error)))
                return
            }

            container.retrieveObject(name: appId) { (error, object) in

                guard let object = object else {
                    Log.error("[AppsController] ❌ retrieveObject error :: \(error)")

                    let error: Error = error ?? AppsController.defaultError()
                    completion(.failure(.fetchObjectError(error)))
                    return
                }
                completion(.success(object.data!))
            }
        }

    }

    fileprivate func storeApp(_ appBinary: Data, name: String, completion: @escaping AppsControllerCompletionHandlet) {

        objstorage?.retrieveContainer(name: storageContainer) { (error, container) in

            guard let container = container else {
                Log.error("[AppsController] ❌ retrieveContainer error :: \(error)")

                let error: Error = error ?? AppsController.defaultError()
                completion(.failure(.retrieveContainerError(error)))
                return
            }

            container.storeObject(name: name, data: appBinary) { (error, object) in
                if let error = error {
                    Log.error("[AppsController] ❌ storeObject error :: \(error)")
                    completion(.failure(.storeObjectError(error)))
                } else {
                    completion(.success())
                }
            }
        }

    }

    static fileprivate func defaultError() -> NSError {
        return NSError(domain: "AppsController", code: 0, userInfo: nil)
    }

}
