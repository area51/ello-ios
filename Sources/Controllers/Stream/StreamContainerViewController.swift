////
///  StreamContainerViewController.swift
//

import SwiftyUserDefaults

let CurrentStreamKey = "Ello.StreamContainerViewController.CurrentStream"

open class StreamContainerViewController: StreamableViewController {
    fileprivate var loggedPromptEventForThisSession = false
    fileprivate var reloadStreamContentObserver: NotificationObserver?
    fileprivate var friendsViewController: StreamViewController?
    fileprivate var appBackgroundObserver: NotificationObserver?
    fileprivate var appForegroundObserver: NotificationObserver?

    open let streamValues: [StreamKind] = [.following, .starred]
    fileprivate lazy var streamLoaded: [Bool] = self.defaultSreamLoadedValues() // needs to hold same number of 'false's as streamValues

    // moved into a separate function to save compile time
    fileprivate func defaultSreamLoadedValues() -> [Bool] {
        return [false, false]
    }

    open var currentStreamIndex: Int {
        get {
            return GroupDefaults[CurrentStreamKey].int ?? 0
        }
        set(newValue) {
            GroupDefaults[CurrentStreamKey] = newValue
        }
    }

    enum Notifications: String {
        case streamDetailTapped = "StreamDetailTappedNotification"
    }

    override open var tabBarItem: UITabBarItem? {
        get { return UITabBarItem.item(.circBig) }
        set { self.tabBarItem = newValue }
    }

    @IBOutlet weak open var scrollView: UIScrollView!
    weak open var navigationBar: ElloNavigationBar!
    @IBOutlet weak open var navigationBarTopConstraint: NSLayoutConstraint!

    open var streamsSegmentedControl: UISegmentedControl!
    open var streamControllerViews: [UIView] = []

    fileprivate var childStreamControllers: [StreamViewController] {
        return self.childViewControllers.filter { $0 is StreamViewController } as! [StreamViewController]
    }

    deinit {
        removeTemporaryNotificationObservers()
        removeNotificationObservers()
    }

    override open func backGestureAction() {
        hamburgerButtonTapped()
    }

    override func setupStreamController() { /* intentially left blank */ }

    override open func viewDidLoad() {
        super.viewDidLoad()
        addNotificationObservers()
        setupStreamsSegmentedControl()
        setupChildViewControllers()
        updateInsets()

        let index = currentStreamIndex
        let stream = streamValues[index]
        let initialController = childStreamControllers[index]
        setupNavigationBar(controller: initialController)

        scrollLogic.prevOffset = initialController.collectionView.contentOffset
        initialController.collectionView.scrollsToTop = true
        streamsSegmentedControl.selectedSegmentIndex = index
        initialController.loadInitialPage()
        streamLoaded[index] = true

        Tracker.sharedTracker.streamAppeared(stream.name)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Rotating the phone after opening a web page results in the
        // streamsSegmentedControl "flattening" to 1pt height.  So we just fix
        // it when the controller is shown again (e.g. when hiding the web page)
        streamsSegmentedControl.frame.size.height = 19
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addTemporaryNotificationObservers()
        if !loggedPromptEventForThisSession {
            Rate.sharedRate.logEvent()
            loggedPromptEventForThisSession = true
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotificationObservers()
    }

    fileprivate func updateInsets() {
        for controller in childStreamControllers {
            updateInsets(navBar: navigationBar, streamController: controller)
        }
    }

    override open func showNavBars(_ scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(navigationBar, visible: true, withConstraint: navigationBarTopConstraint)
        updateInsets()

        if scrollToBottom {
            for controller in childStreamControllers {
                self.scrollToBottom(controller)
            }
        }
    }

    override open func hideNavBars() {
        super.hideNavBars()
        positionNavBar(navigationBar, visible: false, withConstraint: navigationBarTopConstraint)
        updateInsets()
    }

    open class func instantiateFromStoryboard() -> StreamContainerViewController {
        let navController = UIStoryboard.storyboardWithId(.streamContainer) as! UINavigationController
        let streamsController = navController.topViewController
        return streamsController as! StreamContainerViewController
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width: CGFloat = view.bounds.size.width
        let height: CGFloat = view.bounds.size.height

        for (index, view) in streamControllerViews.enumerated() {
            view.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
        }

        scrollView.contentSize = CGSize(width: width * CGFloat(streamValues.count), height: height)

        let selectedIndex = streamsSegmentedControl.selectedSegmentIndex
        let x = CGFloat(selectedIndex) * width
        let rect = CGRect(x: x, y: 0, width: width, height: height)
        scrollView.scrollRectToVisible(rect, animated: false)
    }

    fileprivate func setupNavigationBar(controller: StreamViewController) {
        elloNavigationItem.titleView = streamsSegmentedControl
        elloNavigationItem.leftBarButtonItem = UIBarButtonItem(image: InterfaceImage.burger.normalImage, style: .done, target: self, action: #selector(StreamContainerViewController.hamburgerButtonTapped))
        let searchItem = UIBarButtonItem.searchItem(controller: self)
        let gridListItem = UIBarButtonItem.gridListItem(delegate: controller, isGridView: controller.streamKind.isGridView)
        elloNavigationItem.rightBarButtonItems = [
            searchItem,
            gridListItem,
        ]
        navigationBar.items = [elloNavigationItem]
    }

    fileprivate func setupChildViewControllers() {
        scrollView.isScrollEnabled = false
        scrollView.scrollsToTop = false
        let width: CGFloat = scrollView.frame.size.width
        let height: CGFloat = scrollView.frame.size.height

        for (index, kind) in streamValues.enumerated() {
            let vc = StreamViewController.instantiateFromStoryboard()
            vc.currentUser = currentUser
            vc.streamKind = kind
            vc.createPostDelegate = self
            vc.postTappedDelegate = self
            vc.userTappedDelegate = self
            vc.streamViewDelegate = self
            vc.collectionView.scrollsToTop = false

            vc.willMove(toParentViewController: self)

            let x = CGFloat(index) * width
            let frame = CGRect(x: x, y: 0, width: width, height: height)
            vc.view.frame = frame
            scrollView.addSubview(vc.view)
            streamControllerViews.append(vc.view)

            self.addChildViewController(vc)
            vc.didMove(toParentViewController: self)
            ElloHUD.showLoadingHudInView(vc.view)

            switch kind {
            case .following:
                let noResultsTitle = InterfaceString.FollowingStream.NoResultsTitle
                let noResultsBody = InterfaceString.FollowingStream.NoResultsBody
                friendsViewController = vc
                vc.noResultsMessages = (title: noResultsTitle, body: noResultsBody)
            case .starred:
                let noResultsTitle = InterfaceString.StarredStream.NoResultsTitle
                let noResultsBody = InterfaceString.StarredStream.NoResultsBody
                vc.noResultsMessages = (title: noResultsTitle, body: noResultsBody)
            default:
                break
            }
        }
    }

    fileprivate func setupStreamsSegmentedControl() {
        let control = ElloSegmentedControl(items: streamValues.map{ $0.name })
        control.style = .compact
        control.addTarget(self, action: #selector(StreamContainerViewController.streamSegmentTapped(_:)), for: .valueChanged)
        control.frame.size.height = 19.0
        control.layer.borderWidth = 1.0
        control.selectedSegmentIndex = 0
        control.tintColor = .black
        streamsSegmentedControl = control
    }

    fileprivate func showSegmentIndex(_ index: Int) {
        for controller in childStreamControllers {
            controller.collectionView.scrollsToTop = false
        }

        let currentController = childStreamControllers[index]
        currentController.collectionView.scrollsToTop = true

        let width = view.bounds.size.width
        let height = view.bounds.size.height
        let x = CGFloat(index) * width
        let rect = CGRect(x: x, y: 0, width: width, height: height)
        scrollView.scrollRectToVisible(rect, animated: true)

        currentStreamIndex = index
        let stream = streamValues[currentStreamIndex]
        Tracker.sharedTracker.streamAppeared(stream.name)

        setupNavigationBar(controller: currentController)

        if !streamLoaded[index] {
            streamLoaded[index] = true
            currentController.loadInitialPage()
        }
    }

    // MARK: - IBActions
    let drawerAnimator = DrawerAnimator()

    @IBAction func hamburgerButtonTapped() {
        let drawer = DrawerViewController()
        drawer.currentUser = currentUser

        drawer.transitioningDelegate = drawerAnimator
        drawer.modalPresentationStyle = .custom

        self.present(drawer, animated: true, completion: nil)
    }

    @IBAction func streamSegmentTapped(_ sender: UISegmentedControl) {
        showSegmentIndex(sender.selectedSegmentIndex)
    }
}

public extension StreamContainerViewController {

    func showFriends() {
        showSegmentIndex(0)
        streamsSegmentedControl.selectedSegmentIndex = 0
    }

    func showNoise() {
        showSegmentIndex(1)
        streamsSegmentedControl.selectedSegmentIndex = 1
    }
}

private extension StreamContainerViewController {

    func addTemporaryNotificationObservers() {
        reloadStreamContentObserver = NotificationObserver(notification: NewContentNotifications.reloadStreamContent) {
            [unowned self] _ in
            if let vc = self.friendsViewController {
                ElloHUD.showLoadingHudInView(vc.view)
                vc.loadInitialPage()
            }
        }
    }

    func removeTemporaryNotificationObservers() {
        reloadStreamContentObserver?.removeObserver()
    }

    func addNotificationObservers() {
        appBackgroundObserver = NotificationObserver(notification: Application.Notifications.DidEnterBackground) {
            [unowned self] _ in
            self.loggedPromptEventForThisSession = false
        }
    }

    func removeNotificationObservers() {
        appBackgroundObserver?.removeObserver()
    }
}
