//
//  NotificationManager.swift
//  kitura-helloworld
//
//  Created by Ruslan Maslouski on 3/13/17.
//
//

//import Foundation
import LoggerAPI
import Configuration
import BluemixPushNotifications

enum NotificationManagerType {
    case notify(version: String)
}

enum NotificationManagerError: Error {
    case send(Error)
}

typealias NotificationManagerCompletionHandlet = (MainResult<Void, NotificationManagerError>) -> Void

class NotificationManager {

    private let myPushNotifications: PushNotifications?

    init(configMgr: ConfigurationManager) {

        let isDev = configMgr.isDev
        let appGuid = isDev ? "dc9eac1a-b139-40a6-a402-12dd59aa46ec" : "dc8e4ba2-03f8-4ac2-8a7f-47b85ff277ab"
        let appSecret = isDev ? "bddc9121-15df-4c3c-a8ce-7912f093ea2e" : "f44a5065-e063-4496-8fb1-371278eb8153"

        myPushNotifications = PushNotifications(bluemixRegion: PushNotifications.Region.US_SOUTH,
                                                bluemixAppGuid: appGuid,
                                                bluemixAppSecret: appSecret)

    }

    func send(type: NotificationManagerType, completion: NotificationManagerCompletionHandlet?) {

        let message = Notification.Message(alert: type.message, url: nil)
        send(message: message, completion: completion)
    }

    fileprivate func send(message: Notification.Message, completion: NotificationManagerCompletionHandlet?) {

        let messageExample = Notification.Message(alert: "Testing BluemixPushNotifications", url: nil)
        let notificationExample = Notification(message: messageExample, target: nil, apnsSettings: nil, gcmSettings: nil)

        myPushNotifications?.send(notification: notificationExample) { (error) in
            if let error = error {
                Log.error("[NotificationManager] ❌ Failed to send push notification. Error: \(error)")
                completion?(.failure(.send(error)))
            }
            completion?(.success())
        }
    }

}

fileprivate extension NotificationManagerType {

    var message: String {

        switch self {
        case .notify(let version):
            return "New application with version \(version) available"
        }
    }

}
