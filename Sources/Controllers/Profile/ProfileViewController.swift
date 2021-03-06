////
///  ProfileViewController.swift
//

import FLAnimatedImage


public final class ProfileViewController: StreamableViewController {

    override public var tabBarItem: UITabBarItem? {
        get { return UITabBarItem.item(.Person) }
        set { self.tabBarItem = newValue }
    }

    var _mockScreen: ProfileScreenProtocol?
    public var screen: ProfileScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return _mockScreen ?? self.view as! ProfileScreenProtocol }
    }

    var user: User?
    var headerItems: [StreamCellItem]?
    var responseConfig: ResponseConfig?
    var userParam: String!
    var coverImageHeightStart: CGFloat?
    let initialStreamKind: StreamKind
    var currentUserChangedNotification: NotificationObserver?
    var postChangedNotification: NotificationObserver?
    var relationshipChangedNotification: NotificationObserver?
    var deeplinkPath: String?
    var generator: ProfileGenerator?
    private var isSetup = false

    public init(userParam: String, username: String? = nil) {
        self.userParam = userParam
        self.initialStreamKind = .UserStream(userParam: self.userParam)
        super.init(nibName: nil, bundle: nil)

        if let username = username {
            title = "@\(username)"
        }

        if self.user == nil {
            if let user = ElloLinkedStore.sharedInstance.getObject(self.userParam, type: .UsersType) as? User {
                self.user = user
            }
        }

        sharedInit()

        relationshipChangedNotification = NotificationObserver(notification: RelationshipChangedNotification) { [unowned self] user in
            if self.user?.id == user.id {
                self.updateRelationshipPriority(user.relationshipPriority)
            }
        }
    }

    // this should only be initialized this way for currentUser in tab nav
    public init(user: User) {
        // this user must have the profile property assigned (since it is currentUser)
        self.user = user
        self.userParam = user.id
        self.initialStreamKind = .CurrentUserStream
        super.init(nibName: nil, bundle: nil)

        sharedInit()
        currentUserChangedNotification = NotificationObserver(notification: CurrentUserChangedNotification) { [unowned self] _ in
            self.updateCachedImages()
        }
    }

    private func sharedInit() {
        streamViewController.streamKind = initialStreamKind
        streamViewController.initialLoadClosure = { [unowned self] in self.loadProfile() }
        streamViewController.reloadClosure = { [unowned self] in self.reloadEntireProfile() }
        streamViewController.toggleClosure = { [unowned self] isGridView in self.toggleGrid(isGridView) }
    }

    deinit {
        currentUserChangedNotification?.removeObserver()
        currentUserChangedNotification = nil
        postChangedNotification?.removeObserver()
        postChangedNotification = nil
        relationshipChangedNotification?.removeObserver()
        relationshipChangedNotification = nil
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        if user == nil {
            screen.disableButtons()
        }

        self.generator = ProfileGenerator(
            currentUser: self.currentUser,
            userParam: userParam,
            user: self.user,
            streamKind: self.streamViewController.streamKind,
            destination: self
        )
        view.clipsToBounds = true
        setupNavigationItems()
        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
        screen.relationshipDelegate = streamViewController.dataSource.relationshipDelegate

        if let user = user {
            updateUser(user)
        }
    }

    override public func loadView() {
        let screen = ProfileScreen()
        screen.delegate = self
        screen.navigationItem = elloNavigationItem
        self.view = screen
        viewContainer = screen.streamContainer
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let ratio: CGFloat = ProfileHeaderCellSizeCalculator.ratio
        let headerHeight: CGFloat = view.frame.width / ratio
        let scrollAdjustedHeight = headerHeight - streamViewController.collectionView.contentOffset.y
        let maxHeaderHeight = max(scrollAdjustedHeight, headerHeight)
        screen.updateHeaderHeightConstraints(max: maxHeaderHeight, scrollAdjusted: scrollAdjustedHeight)

        coverImageHeightStart = scrollAdjustedHeight
    }

    override public func didSetCurrentUser() {
        generator?.currentUser = currentUser
        super.didSetCurrentUser()
    }

    override func showNavBars(scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(screen.navigationBar, visible: true, withConstraint: screen.navigationBarTopConstraint)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }

        screen.showNavBars()
    }

    override func hideNavBars() {
        super.hideNavBars()
        positionNavBar(screen.navigationBar, visible: false, withConstraint: screen.navigationBarTopConstraint, animated: true)
        updateInsets()

        let offset = self.streamViewController.collectionView.contentOffset
        let currentUser = (self.user?.id == self.currentUser?.id && self.user?.id != nil)
        screen.hideNavBars(offset, isCurrentUser: currentUser)
    }

    private func updateInsets() {
        updateInsets(navBar: screen.topInsetView, streamController: streamViewController)
    }

    // MARK : private

    private func loadProfile() {
        generator?.load()
    }

    private func reloadEntireProfile() {
        screen.resetCoverImage()
        generator?.load(reload: true)
    }

    private func showUserLoadFailure() {
        let message = InterfaceString.GenericError
        let alertController = AlertViewController(message: message)
        let action = AlertAction(title: InterfaceString.OK, style: .Dark) { _ in
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertController.addAction(action)
        logPresentingAlert("ProfileViewController")
        presentViewController(alertController, animated: true, completion: nil)
    }

    private func setupNavigationItems() {
        let backItem = UIBarButtonItem.backChevron(withController: self)
        let gridListItem = UIBarButtonItem.gridListItem(delegate: streamViewController, isGridView: streamViewController.streamKind.isGridView)
        let shareItem = UIBarButtonItem(image: .Share, target: self, action: #selector(ProfileViewController.sharePostTapped(_:)))
        let moreActionsItem = UIBarButtonItem(image: .Dots, target: self, action: #selector(ProfileViewController.moreButtonTapped))
        let isCurrentUser = userParam == currentUser?.id || userParam == "~\(currentUser)"

        if !isRootViewController() {
            var leftBarButtonItems: [UIBarButtonItem] = []
            leftBarButtonItems.append(UIBarButtonItem.spacer(width: -17))
            leftBarButtonItems.append(backItem)
            if !isCurrentUser {
                leftBarButtonItems.append(UIBarButtonItem.spacer(width: -17))
                leftBarButtonItems.append(moreActionsItem)
            }
            elloNavigationItem.leftBarButtonItems = leftBarButtonItems
        }

        guard !isCurrentUser else {
            elloNavigationItem.rightBarButtonItems = [shareItem, gridListItem]
            return
        }

        guard
            let user = user,
            let currentUser = currentUser
        where user.id != currentUser.id else {
            elloNavigationItem.rightBarButtonItems = []
            return
        }

        var rightBarButtonItems: [UIBarButtonItem] = []
        if user.hasSharingEnabled {
            rightBarButtonItems.append(shareItem)
        }
        rightBarButtonItems.append(gridListItem)

        if !elloNavigationItem.areRightButtonsTheSame(rightBarButtonItems) {
            elloNavigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }

    func moreButtonTapped() {
        guard let user = user else { return }

        let userId = user.id
        let userAtName = user.atName
        let prevRelationshipPriority = user.relationshipPriority
        streamViewController.relationshipController?.launchBlockModal(userId, userAtName: userAtName, relationshipPriority: prevRelationshipPriority) { newRelationshipPriority in
            user.relationshipPriority = newRelationshipPriority
        }
    }

    func sharePostTapped(sourceView: UIView) {
        guard let user = user,
            shareLink = user.shareLink,
            shareURL = NSURL(string: shareLink)
        else { return }

        Tracker.sharedTracker.userShared(user)
        let activityVC = UIActivityViewController(activityItems: [shareURL], applicationActivities: [SafariActivity()])
        if UI_USER_INTERFACE_IDIOM() == .Phone {
            activityVC.modalPresentationStyle = .FullScreen
            logPresentingAlert(readableClassName() ?? "ProfileViewController")
            presentViewController(activityVC, animated: true) { }
        }
        else {
            activityVC.modalPresentationStyle = .Popover
            activityVC.popoverPresentationController?.sourceView = sourceView
            logPresentingAlert(readableClassName() ?? "ProfileViewController")
            presentViewController(activityVC, animated: true) { }
        }
    }

    func toggleGrid(isGridView: Bool) {
        generator?.toggleGrid()
    }

}

extension ProfileViewController: ProfileScreenDelegate {
    public func mentionTapped() {
        guard let user = user else { return }

        createPost(text: "\(user.atName) ", fromController: self)
    }

    public func hireTapped() {
        guard let user = user else { return }

        Tracker.sharedTracker.tappedHire(user)
        let vc = HireViewController(user: user, type: .Hire)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    public func editTapped() {
        onEditProfile()
    }

    public func inviteTapped() {
        onInviteFriends()
    }

    public func collaborateTapped() {
        guard let user = user else { return }

        Tracker.sharedTracker.tappedCollaborate(user)
        let vc = HireViewController(user: user, type: .Collaborate)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: Check for cached coverImage and avatar (only for currentUser)
extension ProfileViewController {
    public func cachedImage(key: CacheKey) -> UIImage? {
        guard user?.id == currentUser?.id else {
            return nil
        }
        return TemporaryCache.load(key)
    }

    public func updateCachedImages() {
        guard let cachedImage = cachedImage(.CoverImage) else {
            return
        }

        screen.coverImage = cachedImage
    }

    public func updateUser(user: User) {
        screen.enableButtons()

        guard user.id == self.currentUser?.id else {
            screen.configureButtonsForNonCurrentUser(isHireable: user.isHireable, isCollaborateable: user.isCollaborateable)
            return
        }

        // only update the avatar and coverImage assets if there is nothing
        // in the cache.  If images are in the cache, that implies that the
        // image could still be unprocessed, so don't set the avatar or
        // coverImage to the old, stale value.
        if cachedImage(.Avatar) == nil {
            self.currentUser?.avatar = user.avatar
        }

        if cachedImage(.CoverImage) == nil {
            self.currentUser?.coverImage = user.coverImage
        }

        screen.configureButtonsForCurrentUser()
    }

    public func updateRelationshipPriority(relationshipPriority: RelationshipPriority) {
        screen.updateRelationshipPriority(relationshipPriority)
        self.user?.relationshipPriority = relationshipPriority
    }
}

// MARK: ProfileViewController: PostsTappedResponder
extension ProfileViewController: PostsTappedResponder {
    public func onPostsTapped() {
        let indexPath = NSIndexPath(forItem: 1, inSection: 0)
        guard streamViewController.dataSource.isValidIndexPath(indexPath) else { return }
        streamViewController.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: true)
    }
}

// MARK: ProfileHeaderResponder
extension ProfileViewController: ProfileHeaderResponder {

    public func onCategoryBadgeTapped(cell: UICollectionViewCell) {
        guard let
            categories = user?.categories
        where user?.categories?.count > 0
        else { return }

        let vc = ProfileCategoriesViewController(categories: categories)
        vc.currentUser = currentUser
        let navVC = ElloNavigationController(rootViewController: vc)
        navVC.modalTransitionStyle = .CrossDissolve
        navVC.modalPresentationStyle = .Custom
        navVC.transitioningDelegate = vc
        presentViewController(navVC, animated: true, completion: nil)
    }

    public func onLovesTapped(cell: UICollectionViewCell) {
        guard let user = self.user else { return }

        let noResultsTitle: String
        let noResultsBody: String
        if user.id == currentUser?.id {
            noResultsTitle = InterfaceString.Loves.CurrentUserNoResultsTitle
            noResultsBody = InterfaceString.Loves.CurrentUserNoResultsBody
        }
        else {
            noResultsTitle = InterfaceString.Loves.NoResultsTitle
            noResultsBody = InterfaceString.Loves.NoResultsBody
        }
        streamViewController.showSimpleStream(.Loves(userId: user.id), title: InterfaceString.Loves.Title, noResultsMessages: (title: noResultsTitle, body: noResultsBody))
    }

    public func onFollowersTapped(cell: UICollectionViewCell) {
        guard let user = self.user else { return }

        let noResultsTitle: String
        let noResultsBody: String
        if user.id == currentUser?.id {
            noResultsTitle = InterfaceString.Followers.CurrentUserNoResultsTitle
            noResultsBody = InterfaceString.Followers.CurrentUserNoResultsBody
        }
        else {
            noResultsTitle = InterfaceString.Followers.NoResultsTitle
            noResultsBody = InterfaceString.Followers.NoResultsBody
        }
        streamViewController.showSimpleStream(.UserStreamFollowers(userId: user.id), title: InterfaceString.Followers.Title, noResultsMessages: (title: noResultsTitle, body: noResultsBody))
    }

    public func onFollowingTapped(cell: UICollectionViewCell) {
        guard let user = user else { return }

        let noResultsTitle: String
        let noResultsBody: String
        if user.id == currentUser?.id {
            noResultsTitle = InterfaceString.Following.CurrentUserNoResultsTitle
            noResultsBody = InterfaceString.Following.CurrentUserNoResultsBody
        }
        else {
            noResultsTitle = InterfaceString.Following.NoResultsTitle
            noResultsBody = InterfaceString.Following.NoResultsBody
        }
        streamViewController.showSimpleStream(.UserStreamFollowing(userId: user.id), title: InterfaceString.Following.Title, noResultsMessages: (title: noResultsTitle, body: noResultsBody))
    }}


// MARK: ProfileViewController: EditProfileResponder
extension ProfileViewController: EditProfileResponder {

    public func onEditProfile() {
        guard let settings = UIStoryboard(name: "Settings", bundle: .None).instantiateInitialViewController() as? SettingsContainerViewController else { return }
        settings.currentUser = currentUser
        navigationController?.pushViewController(settings, animated: true)
    }
}

// MARK: ProfileViewController: StreamViewDelegate
extension ProfileViewController {

    override public func streamViewDidScroll(scrollView: UIScrollView) {
        if let start = coverImageHeightStart {
            screen.updateHeaderHeightConstraints(max: max(start - scrollView.contentOffset.y, start), scrollAdjusted: start - scrollView.contentOffset.y)
        }
        super.streamViewDidScroll(scrollView)
    }
}

// MARK: ProfileViewController: StreamDestination
extension ProfileViewController:  StreamDestination {

    public var pagingEnabled: Bool {
        get { return streamViewController.pagingEnabled }
        set { streamViewController.pagingEnabled = newValue }
    }

    public func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: ElloEmptyCompletion) {
        streamViewController.replacePlaceholder(type, with: items, completion: completion)
    }

    public func setPlaceholders(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad()
        streamViewController.appendUnsizedCellItems(items, withWidth: view.frame.width) { _ in }
        setupNavigationItems()
    }

    public func setPrimaryJSONAble(jsonable: JSONAble) {
        guard let user = jsonable as? User else { return }

        self.user = user
        updateUser(user)

        userParam = user.id
        title = user.atName

        setupNavigationItems()
        Tracker.sharedTracker.profileLoaded(user.atName ?? "(no name)")

        screen.updateRelationshipControl(user: user)

        if let cachedImage = cachedImage(.CoverImage) {
            screen.coverImage = cachedImage
        }
        else if let coverImageURL = user.coverImageURL(viewsAdultContent: currentUser?.viewsAdultContent, animated: true)
        {
            screen.coverImageURL = coverImageURL
        }
    }

    public func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }

    public func primaryJSONAbleNotFound() {
        if let deeplinkPath = self.deeplinkPath,
            deeplinkURL = NSURL(string: deeplinkPath)
        {
            UIApplication.sharedApplication().openURL(deeplinkURL)
            self.deeplinkPath = nil
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.showUserLoadFailure()
        }
        self.streamViewController.doneLoading()
    }
}
