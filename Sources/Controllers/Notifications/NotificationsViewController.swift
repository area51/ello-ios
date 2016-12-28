////
///  NotificationsViewController.swift
//


open class NotificationsViewController: StreamableViewController, NotificationDelegate, NotificationsScreenDelegate {
    var generator: NotificationsGenerator?
    var hasNewContent = false
    var fromTabBar = false
    fileprivate var reloadNotificationsObserver: NotificationObserver?
    fileprivate var newAnnouncementsObserver: NotificationObserver?
    open var categoryFilterType = NotificationFilterType.all
    open var categoryStreamKind: StreamKind { return .notifications(category: categoryFilterType.category) }

    override open var tabBarItem: UITabBarItem? {
        get { return UITabBarItem.item(.bolt) }
        set { self.tabBarItem = newValue }
    }

    override open func loadView() {
        self.view = NotificationsScreen(frame: UIScreen.main.bounds)
    }

    var screen: NotificationsScreen {
        return self.view as! NotificationsScreen
    }

    var navigationNotificationObserver: NotificationObserver?

    public init() {
        super.init(nibName: nil, bundle: nil)
        addNotificationObservers()

        generator = NotificationsGenerator(
            currentUser: currentUser,
            streamKind: categoryStreamKind,
            destination: self
        )
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        navigationNotificationObserver?.removeObserver()
        reloadNotificationsObserver?.removeObserver()
        newAnnouncementsObserver?.removeObserver()
    }

    override open func didSetCurrentUser() {
        generator?.currentUser = currentUser
        super.didSetCurrentUser()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        screen.delegate = self
        title = InterfaceString.Notifications.Title
        elloNavigationItem.rightBarButtonItem = UIBarButtonItem.searchItem(controller: self)

        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        scrollLogic.navBarHeight = 44

        reload()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if hasNewContent && fromTabBar {
            reload()
        }
        fromTabBar = false

        PushNotificationController.sharedController.updateBadgeNumber(0)
    }

    func initialLoad() {
        ElloHUD.showLoadingHudInView(streamViewController.view)
        generator?.load(reload: false)
    }

    func reload() {
        ElloHUD.showLoadingHudInView(streamViewController.view)
        hasNewContent = false

        generator?.streamKind = categoryStreamKind
        generator?.load(reload: true)
    }

    func reloadAnnouncements() {
        generator?.reloadAnnouncements()
    }

    override func setupStreamController() {
        super.setupStreamController()

        streamViewController.streamKind = categoryStreamKind
        streamViewController.announcementDelegate = self
        streamViewController.notificationDelegate = self
        streamViewController.initialLoadClosure = { [weak self] in self?.initialLoad() }
        streamViewController.reloadClosure = { [weak self] in self?.reload() }
    }

    override open func showNavBars(_ scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        screen.animateNavigationBar(visible: true)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override open func hideNavBars() {
        super.hideNavBars()
        screen.animateNavigationBar(visible: false)
        updateInsets()
    }


    // used to provide StreamableViewController access to the container it then
    // loads the StreamViewController's content into
    override func viewForStream() -> UIView {
        return self.screen.streamContainer
    }

    open func activatedCategory(_ filterTypeStr: String) {
        let filterType = NotificationFilterType(rawValue: filterTypeStr)!
        activatedCategory(filterType)
    }

    open func activatedCategory(_ filterType: NotificationFilterType) {
        screen.selectFilterButton(filterType)
        categoryFilterType = filterType

        streamViewController.streamKind = categoryStreamKind
        streamViewController.hideNoResults()
        streamViewController.removeAllCellItems()

        reload()
    }

    open func commentTapped(_ comment: ElloComment) {
        if let post = comment.loadedFromPost {
            postTapped(post)
        }
        else {
            postTapped(postId: comment.postId)
        }
    }

    open func respondToNotification(_ components: [String]) {
        var popToRoot: Bool = true
        if let path = components.safeValue(0) {
            switch path {
            case "posts":
                if let id = components.safeValue(1) {
                    popToRoot = false
                    postTapped(postId: id)
                }
            case "users":
                if let id = components.safeValue(1) {
                    popToRoot = false
                    userParamTapped(id, username: nil)
                }
            default:
                break
            }
        }

        if popToRoot {
            _ = navigationController?.popToRootViewController(animated: true)
        }

        reload()
    }

}

private extension NotificationsViewController {

    func addNotificationObservers() {
        navigationNotificationObserver = NotificationObserver(notification: NavigationNotifications.showingNotificationsTab) { [weak self] components in
            guard let sself = self else { return }
            sself.respondToNotification(components)
        }

        reloadNotificationsObserver = NotificationObserver(notification: NewContentNotifications.reloadNotifications) {
            [weak self] _ in
            guard let sself = self else { return }
            if sself.navigationController?.childViewControllers.count == 1 {
                sself.reload()
            }
            else {
                sself.hasNewContent = true
            }
        }

        newAnnouncementsObserver = NotificationObserver(notification: NewContentNotifications.newAnnouncements) {
            [weak self] _ in
            guard let sself = self else { return }
            sself.reloadAnnouncements()
        }
    }

    func updateInsets() {
        updateInsets(navBar: screen.filterBar, streamController: streamViewController)
    }
}

// MARK: NotificationsViewController: StreamDestination
extension NotificationsViewController: StreamDestination {

    public var pagingEnabled: Bool {
        get { return streamViewController.pagingEnabled }
        set { streamViewController.pagingEnabled = newValue }
    }

    public func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping ElloEmptyCompletion) {
        streamViewController.replacePlaceholder(type, with: items, completion: completion)
    }

    public func setPlaceholders(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad()
        streamViewController.appendUnsizedCellItems(items, withWidth: view.frame.width) { _ in }

        for item in items {
            if let announcement = item.jsonable as? Announcement {
                Tracker.sharedTracker.announcementViewed(announcement)
            }
        }
    }

    public func setPrimary(jsonable: JSONAble) {
        self.streamViewController.doneLoading()
    }

    public func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }

    public func primaryJSONAbleNotFound() {
        self.streamViewController.doneLoading()
    }
}

// MARK: NotificationsViewController:
extension NotificationsViewController: AnnouncementDelegate {
    public func markAnnouncementAsRead(announcement: Announcement) {
        Tracker.sharedTracker.announcementDismissed(announcement)
        generator?.markAnnouncementAsRead(announcement)
        postNotification(JSONAbleChangedNotification, value: (announcement, .delete))
    }
}
