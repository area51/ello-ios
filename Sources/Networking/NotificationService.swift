////
///  NotificationService.swift
//

import FutureKit


open class NotificationService {

    public init() {}

    open func loadAnnouncements() -> Future<Announcement> {
        let promise = Promise<Announcement>()
        ElloProvider.shared.elloRequest(
            .announcements,
            success: { (data, responseConfig) in
                if let results = data as? Announcement {
                    promise.completeWithSuccess(results)
                }
                else {
                    let error = NSError.uncastableJSONAble()
                    promise.completeWithFail(error)
                }
            },
            failure: { error, _ in
                promise.completeWithFail(error)
            }
        )
        return promise.future
    }

    open func markAnnouncementAsRead(_ announcement: Announcement) -> Future<Announcement> {
        let promise = Promise<Announcement>()
        ElloProvider.shared.elloRequest(.markAnnouncementAsRead,
            success: { _ in
                promise.completeWithSuccess(announcement)
            },
            failure: { error, _ in
                promise.completeWithFail(error)
            }
        )
        return promise.future
    }

}
