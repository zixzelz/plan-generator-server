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

enum BuddyError: Error {
    case setNewVersion(Error)
}

typealias BuddyCompletionHandlet = (MainResult<Void, BuddyError>) -> Void

class Buddy {

    func setNewVersion(version: String, url: String, completion: @escaping BuddyCompletionHandlet) {

        let httpResource = HttpResource(schema: "https", host: "api.buddyplatform.com", port: "80")
        let headers = ["Content-Type": "application/json", "Accept": "application/json"]
        let data = BuddySetNewVersionRequestBody(version: version, url: url).data()

        let resource = httpResource.resourceByAddingPathComponent(pathComponent: "/metadata/app/latestVersion")
        HttpClient.put(resource: resource, headers: headers, data: data) { (error, status, headers, data) in
            guard let _ = data else {
                Log.error("[Buddy] ❌ setNewVersion error :: \(error)")
                
                let error: Error = error ?? NSError(domain: "Buddy", code: 0, userInfo: nil)
                completion(.failure(.setNewVersion(error)))
                return
            }
            completion(.success())
        }
    }
}

fileprivate class BuddySetNewVersionRequestBody {
    private let dict: [String: Any]

    init(version: String, url: String) {

        dict = [
            "value": [
                "version": "1.1",
                "url": "https://www.allaboutswift.com/dev/2016/7/12/gcd-with-swfit3"]
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
