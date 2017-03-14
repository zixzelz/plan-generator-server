//
//  Buddy.swift
//  kitura-helloworld
//
//  Created by Ruslan Maslouski on 3/14/17.
//
//

import Foundation
//import Kitura
import SimpleHttpClient
import LoggerAPI
import SwiftyJSON

enum BuddyError: Error {
    case setNewVersion(Error)
    case register(Error?)
    case intrnal
    case parse
}

typealias BuddyCompletionHandlet = (MainResult<Void, BuddyError>) -> Void

class Buddy {

    typealias BuddyRegisterCompletionHandlet = (MainResult<String, BuddyError>) -> Void

    let UniqueID = "ba6b0405-1ee9-4154-a3e1-090f2c0425e3"
    let PlatformType = "IBM Bluemix"

    func setNewVersion(version: String, url: String, completion: @escaping BuddyCompletionHandlet) {

        register { (result) in

            guard case .success(let token) = result else {
                guard case .failure(let error) = result else { completion(.failure(.intrnal)); return }
                completion(.failure(error))
                return
            }

            let httpResource = HttpResource(schema: "https", host: "api.buddyplatform.com", port: "80")
            let headers = ["Content-Type": "application/json", "Accept": "application/json", "Authorization": "Buddy \(token)"]
            let data = BuddySetNewVersionRequestBody(version: version, url: url).data()

            let resource = httpResource.resourceByAddingPathComponent(pathComponent: "/metadata/app/latestVersion")
            HttpClient.put(resource: resource, headers: headers, data: data) { (error, status, headers, data) in
                guard let _ = data, error == nil else {
                    Log.error("[Buddy] ❌ setNewVersion error :: \(error)")

                    let error: Error = error ?? NSError(domain: "Buddy", code: 0, userInfo: nil)
                    completion(.failure(.setNewVersion(error)))
                    return
                }

                completion(.success())
            }
        }

    }

    fileprivate func register(completion: @escaping BuddyRegisterCompletionHandlet) {

        let req = [
            "appid": "bbbbbc.MgwDGPdPrNlxc",
            "appkey": "93c16878-6db6-9b51-240d-fa76bd2acf60",
            "uniqueId": UniqueID,
            "platform": "REST Client: \(PlatformType)",
        ];

        let httpResource = HttpResource(schema: "https", host: "api.buddyplatform.com", port: "80")
        let headers = ["Content-Type": "application/json", "Accept": "application/json"]

        guard let data = try? JSONSerialization.data(withJSONObject: req, options: .prettyPrinted) else {
            completion(.failure(.register(nil)))
            return
        }

        let resource = httpResource.resourceByAddingPathComponent(pathComponent: "/devices")
        HttpClient.post(resource: resource, headers: headers, data: data) { (error, status, headers, data) in
            guard let data = data, error == nil else {
                Log.error("[Buddy] ❌ register error :: \(error)")

                completion(.failure(.register(error)))
                return
            }

            let json = JSON(data: data)
            guard let token = json["result"]["accessToken"].string else {
                Log.error("[Buddy] ❌ register error parse result")

                completion(.failure(.parse))
                return
            }

            completion(.success(token))
        }

    }

}

fileprivate class BuddySetNewVersionRequestBody {
    private let dict: [String: Any]

    init(version: String, url: String) {

        dict = [
            "value": [
                "version": version,
                "url": url]
        ]
    }

    func data() -> Data? {

        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        } catch {
            Log.error("[Buddy] \(error.localizedDescription)")
        }

        return jsonData
    }
}
