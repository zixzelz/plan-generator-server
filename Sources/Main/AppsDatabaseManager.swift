//
//  AppsDatabaseManager.swift
//  plan-generator-server
//
//  Created by Ruslan Maslouski on 4/1/17.
//
//

import Foundation
import SwiftyJSON
import Configuration
import LoggerAPI
import CloudFoundryEnv
import CloudFoundryConfig
import CouchDB

class AppsDatabaseManager {

    private let dbMgr: DatabaseManager?

    init(configMgr: ConfigurationManager) {

        let dbName = configMgr.isDev ? "apps-dev" : "apps"

        // Get database connection details...
        let cloudantServ: Service? = configMgr.getServices(type: "cloudantNoSQLDB").first
        dbMgr = DatabaseManager(dbName: dbName, cloudantServ: cloudantServ)
    }

    public func getLatestAppVersion(completion: @escaping GetValueCH) {

        guard let dbMgr = self.dbMgr else {
            Log.error(">> No database manager.")
            completion(.failure(.dbMgr))
            return
        }

        dbMgr.getDatabase() { (db: Database?, error: NSError?) in
            guard let db = db else {
                Log.error(">> No database.")
                completion(.failure(.noDatabase))
                return
            }

            db.queryByView("latest_app", ofDesign: "main_design", usingParameters: [.limit(1), .descending(true)]) { docs, error in
                guard let docs = docs else {
                    Log.error(">> Could not read from database or none exists.")
                    completion(.failure(.dbMgr))
                    return
                }

                Log.info(">> Successfully retrived all docs from db.")

                let doc = docs["rows"].array?.first
                let id = doc?["id"].string!
                let version = doc?["value"]["bundle_version"].string!

                let res = ["id": id!, "version": version!]

                completion(.success(res))
            }
        }
    }

    public func getApp(appId: String, completion: @escaping GetValueCH) {

        guard let dbMgr = self.dbMgr else {
            Log.error(">> No database manager.")
            completion(.failure(.dbMgr))
            return
        }

        dbMgr.getDatabase() { (db: Database?, error: NSError?) in
            guard let db = db else {
                Log.error(">> No database.")
                completion(.failure(.noDatabase))
                return
            }

            db.retrieve(appId) { docs, error in
                guard let doc = docs else {
                    Log.error(">> Could not read from database or none exists.")
                    completion(.failure(.dbMgr))
                    return
                }

                Log.info(">> Successfully retrived app from db.")

                let id = doc["_id"].string!
                let version = doc["bundle_version"].string!

                let res = ["id": id, "version": version]

                completion(.success(res))
            }
        }
    }

    public func addAppVersion(version: String, completion: @escaping StoreValueCH) {

        let json: [String: Any] = [ "bundle_version": version, "timestamp": Date().timeIntervalSince1970]

        guard let dbMgr = self.dbMgr else {
            Log.error(">> No database manager.")
            completion(.failure(.dbMgr))
            return
        }

        dbMgr.getDatabase() { (db: Database?, error: NSError?) in
            guard let db = db else {
                Log.error(">> No database.")
                completion(.failure(.noDatabase))
                return
            }

            db.create(JSON(json), callback: { (id: String?, rev: String?, document: JSON?, error: NSError?) in

                if let error = error {
                    Log.error(">> Could not persist document to database.")
                    Log.error(">> Error: \(error)")
                    completion(.failure(.storeData(error)))
                } else if let id = id {
                    Log.info(">> Successfully created the following JSON document in CouchDB:\n\t\(document)")
                    completion(.success(id))
                } else {
                    Log.error(">> internalError.")
                    completion(.failure(.internalError))
                }
            })
        }
    }

}
