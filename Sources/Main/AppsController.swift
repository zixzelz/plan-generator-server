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
import CloudFoundryEnv
import CloudFoundryConfig
import CouchDB

enum AppsControllerError: Error {
    case retrieveContainerError(Error)
    case storeObjectError(Error)
    case fetchObjectError(Error)
    case setNewVersion
    case sendNotification
    case createManifest(Error?)
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
        }
    }
}

typealias AppsControllerCompletionHandlet = (MainResult<Void, AppsControllerError>) -> Void
typealias GetAppControllerCompletionHandlet = (MainResult<Data, AppsControllerError>) -> Void

class AppsController {

    private let objstorage: ObjectStorage?
    private let dbName = "mydb"
    private let dbMgr: DatabaseManager?
    private let notificationManager: NotificationManager?

    private var storageContainer: String
    
    private var DefaultName = "build.ipa"
    private var BuildManifest = "https://plangenerator.mybluemix.net/api/apps"
    private var BuildUrl = "https://plangenerator.mybluemix.net/api/storage/build.ipa"

    init(configMgr: ConfigurationManager) {

        // Get database connection details...
        let cloudantServ: Service? = configMgr.getServices(type: "cloudantNoSQLDB").first
        dbMgr = DatabaseManager(dbName: dbName, cloudantServ: cloudantServ)
        notificationManager = NotificationManager(configMgr: configMgr)

        storageContainer = configMgr.isDev ? "apps-dev" : "apps"
        BuildManifest = configMgr.url + "/api/apps"
        BuildUrl = configMgr.url + "/api/storage/" + DefaultName
        
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
//        let filePath = TemporaryFileCacheManager().saveFile(name: "temp.pdf", data: app)

        storeApp(app, name: DefaultName) { (result) in

            guard case .success() = result else {
                completion(result)
                return
            }

            UserDefaults.standard.set(version, forKey: "bundle-version")

            self.notificationManager?.send(type: .notify(version: version), completion: { (result) in

                guard case .success() = result else {
                    completion(.failure(.sendNotification))
                    return
                }

                completion(.success())
            })
        }
    }

    func getLatestVersion(appId: String = "") -> [String: String]? {
        guard let version = UserDefaults.standard.string(forKey: "bundle-version") else { return nil }
        return ["version": version, "url": BuildManifest]
    }

    func manifest(appId: String, completion: @escaping GetAppControllerCompletionHandlet) {

        guard let version = UserDefaults.standard.string(forKey: "bundle-version") else {
            completion(.failure(.createManifest(nil)))
            return
        }

        let asset = [
            "kind": "software-package",
            "url": BuildUrl,
        ]

        let metadata = [
            "bundle-identifier": "com.grsu.PlanGenerator",
            "bundle-version": version,
            "kind": "software",
            "title": "PlanGenerator",
        ]
        let items: [String: Any] = ["assets": [asset], "metadata": metadata]
        let dict: [String: Any] = ["items": [items]]

        let nsDict: AnyObject = NSDictionary(dictionary: dict)

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: nsDict, format: PropertyListSerialization.PropertyListFormat.xml, options: 0)
            completion(.success(data))
        } catch {
            completion(.failure(.createManifest(error)))
        }
    }

    func app(appId: String, completion: @escaping GetAppControllerCompletionHandlet) {

        objstorage?.retrieveContainer(name: "apps") { (error, container) in

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

    /**
     * Gets all Visitors.
     * REST API example:
     * <code>
     * GET http://localhost:8080/api/visitors
     * </code>
     *
     * Response:
     * <code>
     * [ "Bob", "Jane" ]
     * </code>
     * @return An array of all the Visitors
     */
//    public func getVisitors(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
//        // If no database, return empty array.
//        guard let dbMgr = self.dbMgr else {
//            Log.warning(">> No database manager.")
//            response.status(.OK).send(json: JSON([]))
//            next()
//            return
//        }
//
//        dbMgr.getDatabase() { (db: Database?, error: NSError?) in
//            guard let db = db else {
//                Log.error(">> No database.")
//                response.status(.internalServerError)
//                next()
//                return
//            }
//
//            db.retrieveAll(includeDocuments: true) { docs, error in
//                guard let docs = docs else {
//                    Log.error(">> Could not read from database or none exists.")
//                    response.status(.badRequest).send("Error could not read from database or none exists")
//                    return
//                }
//
//                Log.info(">> Successfully retrived all docs from db.")
//                let names = docs["rows"].map { _, row in
//                    return row["doc"]["name"].string ?? ""
//                }
//                response.status(.OK).send(json: JSON(names))
//                next()
//            }
//        }
//    }
//
//    /**
//     * Creates a new Visitor.
//     *
//     * REST API example:
//     * <code>
//     * POST http://localhost:8080/api/visitors
//     * <code>
//     * POST Body:
//     * <code>
//     * {
//     *   "name":"Bob"
//     * }
//     * </code>
//     */
//    public func addVisitors(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
//        guard let jsonPayload = request.body?.asJSON else {
//            try response.status(.badRequest).send("JSON payload not provided!").end()
//            return
//        }
//
//        let name = jsonPayload["name"].string ?? ""
//        //let json: [String: Any] = [ "name": name ]
//
//        guard let dbMgr = self.dbMgr else {
//            Log.warning(">> No database manager.")
//            response.status(.OK).send("Hello \(name)!")
//            next()
//            return
//        }
//
//        dbMgr.getDatabase() { (db: Database?, error: NSError?) in
//            guard let db = db else {
//                Log.error(">> No database.")
//                response.status(.internalServerError)
//                next()
//                return
//            }
//
//            db.create(jsonPayload, callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in
//                if let _ = error {
//                    Log.error(">> Could not persist document to database.")
//                    Log.error(">> Error: \(error)")
//                    response.status(.OK).send("Hello \(name)!")
//                } else {
//                    Log.info(">> Successfully created the following JSON document in CouchDB:\n\t\(document)")
//                    response.status(.OK).send("Hello \(name)! I added you to the database.")
//                }
//                next()
//            })
//        }
//    }

}
