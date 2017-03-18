/*
* Copyright IBM Corporation 2017
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation
import Kitura
import SwiftyJSON
import LoggerAPI
import Configuration

public class Controller {
    let router: Router
    private let configMgr: ConfigurationManager

    private let appController: AppsController

    var port: Int {
        get { return configMgr.port }
    }

    init() throws {

        // Get environment variables from config.json or environment variables
        let configFile = URL(fileURLWithPath: #file).appendingPathComponent("../config.json").standardized
        configMgr = ConfigurationManager()
        configMgr.load(url: configFile).load(.environmentVariables)

        appController = AppsController(configMgr: configMgr)

        // All web apps need a Router instance to define routes
        router = Router()
        router.all("/", middleware: StaticFileServer())
        router.all("/api/apps", middleware: BodyParser())
        router.get("/api/apps", handler: getApplication)
        router.post("/api/apps", handler: addApplication)
        router.get("/api/storage/:objectId", handler: getObject)
    }

    public func getApplication(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        appController.manifest(appId: "") { (result) in

            switch result {
            case .success(let data):
                response.headers["Content-Type:"] = "application/xml"
                response.status(.OK).send(data: data)
                next()
            case .failure(let error):
                try? response.status(.internalServerError).send(json: JSON(["message": error.description])).end()
            }
        }
    }

    public func getObject(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let objectId = request.parameters["objectId"] else {
            try? response.status(.badRequest).send(json: JSON(["message": "No object ID"])).end()
            return
        }

        appController.app(appId: objectId) { (result) in

            switch result {
            case .success(let data):
                response.status(.OK).send(data: data)
                next()
            case .failure(let error):
                try? response.status(.internalServerError).send(json: JSON(["message": error.description])).end()
            }
        }

    }

    public func addApplication(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let (appBinary, version) = getAppBinary(fromRequest: request) else {
            try? response.status(.badRequest).send("error!").end()
            return
        }

        appController.add(app: appBinary, version: version) { (result) in

            switch result {
            case .success():
                response.status(.OK).send(json: JSON(["message": "Success"]))
                next()
            case .failure(let error):
                try? response.status(.internalServerError).send(json: JSON(["message": error.description])).end()
            }
        }

    }

    func showFolder(fileManager: FileManager, packagePath: String) {
        do {
            Log.warning("⚠️ Path: \(packagePath)")

            let packages = try fileManager.contentsOfDirectory(atPath: packagePath)
            Log.warning("☢️ \(packages)")

            for package in packages {

                let potentialResource = "\(packagePath)/\(package)"
                showFolder(fileManager: fileManager, packagePath: potentialResource)
            }
        } catch {
            Log.warning("❌ Error")
        }
    }

}

fileprivate extension Controller {

    fileprivate func getAppBinary(fromRequest request: RouterRequest) -> (Data, String)? {

        guard let appPart = request.body?.asMultiPart?.first else {
            Log.warning("❌ App Part payload not provided!")
            return nil
        }
        guard let version = request.body?.asMultiPart?.last?.body.asText, version.components(separatedBy: ".").count > 1 else {
            Log.warning("❌ Version Part payload not provided!")
            return nil
        }

        Log.warning("⚠️ Upload file type: \(appPart.type) version: \(version)")
        guard case .raw(let data) = appPart.body else {
            Log.warning("❌ Couldn't process image binary from multi-part form")
            return nil
        }

        return (data, version)
    }

}
