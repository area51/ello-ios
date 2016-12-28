////
///  SearchViewController.swift
//

open class SearchViewController: StreamableViewController {
    var searchText: String?

    var _mockScreen: SearchScreenProtocol?
    open var screen: SearchScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return _mockScreen ?? self.view as! SearchScreenProtocol }
    }

    override open func loadView() {
        let screen = SearchScreen(frame: UIScreen.main.bounds, isSearchView: true)
        self.view = screen
        screen.delegate = self
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        streamViewController.pullToRefreshEnabled = false
        screen.gridListItem = UIBarButtonItem.gridListItem(delegate: streamViewController, isGridView: streamViewController.streamKind.isGridView)
        screen.hasGridViewToggle = streamViewController.streamKind.hasGridViewToggle
        updateInsets()
    }

    open func searchForPosts(_ terms: String) {
        screen.searchField.text = terms
        screen.searchForText()
    }

    override func viewForStream() -> UIView {
        return screen.viewForStream()
    }

    override func showNavBars(_ scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(screen.navigationBar, visible: true)
        screen.showNavBars()
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override func hideNavBars() {
        super.hideNavBars()
        positionNavBar(screen.navigationBar, visible: false)
        screen.hideNavBars()
        updateInsets()
    }

    fileprivate func updateInsets() {
        updateInsets(navBar: screen.searchControlsContainer, streamController: streamViewController)
    }

}

extension SearchViewController: SearchScreenDelegate {

    public func searchCanceled() {
       _ = navigationController?.popViewController(animated: true)
    }

    public func searchFieldCleared() {
        showNavBars(false)
        searchText = ""
        streamViewController.removeAllCellItems()
        streamViewController.loadingToken.cancelInitialPage()
        streamViewController.noResultsMessages = (title: "", body: "")
        screen.hasGridViewToggle = false
    }

    public func searchFieldChanged(_ text: String, isPostSearch: Bool) {
        loadEndpoint(text, isPostSearch: isPostSearch)
    }

    public func searchShouldReset() {
        streamViewController.hideNoResults()
    }

    public func toggleChanged(_ text: String, isPostSearch: Bool) {
        searchShouldReset()
        loadEndpoint(text, isPostSearch: isPostSearch, checkSearchText: false)
    }

    public func findFriendsTapped() {
        let responder = target(forAction: #selector(InviteResponder.onInviteFriends), withSender: self) as? InviteResponder
        responder?.onInviteFriends()
    }

    fileprivate func loadEndpoint(_ text: String, isPostSearch: Bool, checkSearchText: Bool = true) {
        if text.characters.count < 2 { return }  // just.. no (and the server doesn't guard against empty/short searches)
        if checkSearchText && searchText == text { return }  // a search is already in progress for this text
        streamViewController.hideNoResults()
        trackSearch(text, isPostSearch: isPostSearch)
        searchText = text
        let endpoint = isPostSearch ? ElloAPI.searchForPosts(terms: text) : ElloAPI.searchForUsers(terms: text)
        streamViewController.noResultsMessages = (title: InterfaceString.Search.NoMatches, body: InterfaceString.Search.TryAgain)
        let streamKind = StreamKind.simpleStream(endpoint: endpoint, title: "")
        screen.hasGridViewToggle = streamKind.hasGridViewToggle
        streamViewController.streamKind = streamKind
        streamViewController.removeAllCellItems()
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
    }

    public func trackSearch(_ text: String, isPostSearch: Bool) {
        if isPostSearch {
            if text.hasPrefix("#") {
                Tracker.sharedTracker.searchFor("hashtags")
            }
            else {
                Tracker.sharedTracker.searchFor("posts")
            }
        }
        else {
            Tracker.sharedTracker.searchFor("users")
        }
    }
}
