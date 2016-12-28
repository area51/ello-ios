////
///  NewContentService.swift
//

import Foundation
import SwiftyUserDefaults

public struct NewContentNotifications {
    public static let newAnnouncements = TypedNotification<Void?>(name: "NewAnnouncementsNotification")
    public static let newNotifications = TypedNotification<Void?>(name: "NewNotificationsNotification")
    public static let newStreamContent = TypedNotification<Void?>(name: "NewStreamContentNotification")
    public static let reloadStreamContent = TypedNotification<Void?>(name: "ReloadStreamContentNotification")
    public static let reloadNotifications = TypedNotification<Void?>(name: "ReloadNotificationsNotification")
}

open class NewContentService {
    var timer: Timer?
    public init(){}
}

public extension NewContentService {

    public func startPolling() {
        checkForNewNotifications()
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(NewContentService.checkForNewContent), userInfo: nil, repeats: false)
    }

    public func restartPolling() {
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(NewContentService.checkForNewContent), userInfo: nil, repeats: false)
    }

    public func stopPolling() {
        timer?.invalidate()
    }

    @objc
    public func checkForNewContent() {
        stopPolling()
        let (restart, done) = afterN(restartPolling)
        checkForNewNotifications(restart())
        checkForNewStreamContent(restart())
        done()
    }

    public func updateCreatedAt(_ jsonables: [JSONAble], streamKind: StreamKind) {
        let old = Date(timeIntervalSince1970: 0)
        let new = newestDate(jsonables)
        let storedKey = streamKind.lastViewedCreatedAtKey
        let storedDate = GroupDefaults[storedKey].date ?? old
        let mostRecent = new > storedDate ? new : storedDate
        GroupDefaults[streamKind.lastViewedCreatedAtKey] = mostRecent
    }
}


private extension NewContentService {

    func newestDate(_ jsonables: [JSONAble]) -> Date {
        let old = Date(timeIntervalSince1970: 0)
        return jsonables.reduce(old) {
            (date, jsonable) -> Date in
            if let post = jsonable as? Post {
                return post.createdAt as Date > date ? post.createdAt as Date : date
            }
            else if let notification = jsonable as? Notification {
                return notification.createdAt as Date > date ? notification.createdAt as Date : date
            }
            else if let activity = jsonable as? Activity {
                return activity.createdAt as Date > date ? activity.createdAt as Date : date
            }
            return date
        }
    }

    func checkForNewNotifications(_ done: @escaping BasicBlock = {}) {
        let storedKey = StreamKind.notifications(category: nil).lastViewedCreatedAtKey
        let storedDate = GroupDefaults[storedKey].date

        ElloProvider.shared.elloRequest(
            ElloAPI.notificationsNewContent(createdAt: storedDate),
            success: { (_, responseConfig) in
                if let statusCode = responseConfig.statusCode, statusCode == 204 {
                    postNotification(NewContentNotifications.newNotifications, value: nil)
                }

                done()
            },
            failure: { _ in done() })
    }

    func checkForNewAnnouncements(_ done: @escaping BasicBlock = {}) {
        let storedKey = StreamKind.announcements.lastViewedCreatedAtKey
        let storedDate = GroupDefaults[storedKey].date

         ElloProvider.shared.elloRequest(
             ElloAPI.announcementsNewContent(createdAt: storedDate),
             success: { (_, responseConfig) in
                 if let statusCode = responseConfig.statusCode, statusCode == 204 {
                     postNotification(NewContentNotifications.newAnnouncements, value: nil)
                 }

                 done()
             },
             failure: { _ in done() })
    }

    func checkForNewStreamContent(_ done: @escaping BasicBlock = {}) {
        let storedKey = StreamKind.following.lastViewedCreatedAtKey
        let storedDate = GroupDefaults[storedKey].date

        ElloProvider.shared.elloRequest(
            ElloAPI.friendNewContent(createdAt: storedDate),
            success: { (_, responseConfig) in
                if let lastModified = responseConfig.lastModified {
                    GroupDefaults[StreamKind.following.lastViewedCreatedAtKey] = lastModified.toDate(HTTPDateFormatter)
                }

                if let statusCode = responseConfig.statusCode, statusCode == 204 {
                    postNotification(NewContentNotifications.newStreamContent, value: nil)
                }

                done()
            },
            failure: { _ in done() })
    }
}
