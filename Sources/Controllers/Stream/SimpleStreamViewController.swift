////
///  SimpleStreamController.swift
//

import Foundation

open class SimpleStreamViewController: StreamableViewController {
    override open func trackerName() -> String {
        return "\(endpoint.description)ViewController"
    }

    var navigationBar: ElloNavigationBar!
    let endpoint: ElloAPI

    required public init(endpoint: ElloAPI, title: String) {
        self.endpoint = endpoint
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let streamKind = StreamKind.simpleStream(endpoint: endpoint, title: title ?? "")

        setupNavigationBar()
        setupNavigationItems(streamKind: streamKind)

        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        scrollLogic.navBarHeight = 44
        streamViewController.streamKind = streamKind
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
    }

    override func viewForStream() -> UIView {
        return view
    }

    override open func didSetCurrentUser() {
        if isViewLoaded {
            streamViewController.currentUser = currentUser
        }
        super.didSetCurrentUser()
    }

    override open func showNavBars(_ scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(navigationBar, visible: true)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override open func hideNavBars() {
        super.hideNavBars()
        positionNavBar(navigationBar, visible: false)
        updateInsets()
    }

    // MARK: Private

    fileprivate func updateInsets() {
        updateInsets(navBar: navigationBar, streamController: streamViewController)
    }

    fileprivate func setupNavigationBar() {
        navigationBar = ElloNavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: ElloNavigationBar.Size.height))
        navigationBar.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        view.addSubview(navigationBar)
    }

    fileprivate func setupNavigationItems(streamKind: StreamKind) {
        let backItem = UIBarButtonItem.backChevron(withController: self)
        elloNavigationItem.leftBarButtonItems = [backItem]
        elloNavigationItem.fixNavBarItemPadding()
        navigationBar.items = [elloNavigationItem]

        var rightBarButtonItems: [UIBarButtonItem] = []
        rightBarButtonItems.append(UIBarButtonItem.searchItem(controller: self))
        if streamKind.hasGridViewToggle {
            rightBarButtonItems.append(UIBarButtonItem.gridListItem(delegate: streamViewController, isGridView: streamKind.isGridView))
        }
        elloNavigationItem.rightBarButtonItems = rightBarButtonItems
    }

}
