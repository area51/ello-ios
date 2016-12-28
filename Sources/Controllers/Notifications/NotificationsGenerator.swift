////
///  NotificationsGenerator.swift
//

public final class NotificationsGenerator: StreamGenerator {
    public var currentUser: User?
    public var streamKind: StreamKind

    fileprivate var notifications: [Activity] = []
    fileprivate var announcements: [Announcement] = []
    fileprivate var hasNotifications: Bool?

    weak public var destination: StreamDestination?

    fileprivate var localToken: String!
    fileprivate var loadingToken = LoadingToken()

    public init(
        currentUser: User?,
        streamKind: StreamKind,
        destination: StreamDestination?
        ) {
        self.currentUser = currentUser
        self.streamKind = streamKind
        self.destination = destination
        self.localToken = loadingToken.resetInitialPageLoadingToken()
    }

    public func load(reload: Bool = false) {
        localToken = loadingToken.resetInitialPageLoadingToken()

        if reload {
            announcements = []
            notifications = []
        }

        setPlaceHolders()
        loadAnnouncements()
        loadNotifications()
    }

    public func reloadAnnouncements() {
        loadAnnouncements()
    }

    func setPlaceHolders() {
        destination?.setPlaceholders(items: [
            StreamCellItem(type: .placeholder, placeholderType: .announcements),
            StreamCellItem(type: .placeholder, placeholderType: .notifications),
        ])
    }

    func markAnnouncementAsRead(_ announcement: Announcement) {
        NotificationService().markAnnouncementAsRead(announcement)
            .onSuccess { [weak self] _ in
                self?.announcements = []
            }
            .onFail { _ in }
    }

    func loadAnnouncements() {
        guard case let .notifications(category) = streamKind, category == nil else {
            compareAndUpdateAnnouncements([])
            return
        }

        NotificationService().loadAnnouncements()
            .onSuccess { [weak self] announcement in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                sself.compareAndUpdateAnnouncements([announcement])
            }
            .onFail { [weak self] _ in
                self?.compareAndUpdateAnnouncements([])
            }
    }

    fileprivate func compareAndUpdateAnnouncements(_ newAnnouncements: [Announcement]) {
        guard !announcementsAreSame(newAnnouncements) else { return }

        self.announcements = newAnnouncements
        let announcementItems = StreamCellItemParser().parse(newAnnouncements, streamKind: .announcements, currentUser: self.currentUser)
        self.destination?.replacePlaceholder(type: .announcements, items: announcementItems) {}
    }

    func announcementsAreSame(_ newAnnouncements: [Announcement]) -> Bool {
        return announcements.count == newAnnouncements.count && announcements.enumerated().all({ (index, announcement) in
            return announcement.id == newAnnouncements[index].id
        })
    }

    func loadNotifications() {
        StreamService().loadStream(
            streamKind: streamKind,
            success: { [weak self] (jsonables, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                guard let notifications = jsonables as? [Activity] else { return }

                sself.notifications = notifications
                // setting primaryJSONAble also triggers the "done loading" code
                sself.destination?.setPrimary(jsonable: JSONAble(version: JSONAbleVersion))
                sself.destination?.setPagingConfig(responseConfig: responseConfig)

                let notificationItems = sself.parse(jsonables: notifications)
                if notificationItems.count == 0 {
                    sself.hasNotifications = false
                    sself.destination?.replacePlaceholder(type: .notifications, items: []) {
                        sself.destination?.pagingEnabled = false
                    }
                }
                else {
                    sself.hasNotifications = true
                    sself.destination?.replacePlaceholder(type: .notifications, items: notificationItems) {
                        sself.destination?.pagingEnabled = true
                    }
                }
            },
            failure: { [weak self] _ in
                self?.destination?.primaryJSONAbleNotFound()
            },
            noContent: { [weak self] in
                self?.destination?.primaryJSONAbleNotFound()
            }
        )
    }
}
