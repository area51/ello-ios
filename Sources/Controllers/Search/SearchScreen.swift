////
///  SearchScreen.swift
//

public protocol SearchScreenDelegate: class {
    func searchCanceled()
    func searchFieldCleared()
    func searchFieldChanged(_ text: String, isPostSearch: Bool)
    func searchShouldReset()
    func toggleChanged(_ text: String, isPostSearch: Bool)
    func findFriendsTapped()
}

public protocol SearchScreenProtocol: class {
    var delegate: SearchScreenDelegate? { get set }
    var hasBackButton: Bool { get set }
    var hasGridViewToggle: Bool { get set }
    var gridListItem: UIBarButtonItem? { get set }
    var searchField: UITextField { get }
    var navigationBar: ElloNavigationBar { get }
    var searchControlsContainer: UIView { get }
    func showNavBars()
    func hideNavBars()
    func searchForText()
    func viewForStream() -> UIView
    func updateInsets(bottom: CGFloat)
}

open class SearchScreen: UIView, SearchScreenProtocol {
    struct Size {
        static let containerMargin: CGFloat = 15
    }

    fileprivate var debounced: ThrottledBlock
    open let navigationBar = ElloNavigationBar()
    open let searchField = UITextField()
    open let searchControlsContainer = UIView()
    fileprivate let postsToggleButton = StyledButton(style: .SquareBlack)
    fileprivate let peopleToggleButton = StyledButton(style: .SquareBlack)
    fileprivate var streamViewContainer = UIView()
    open fileprivate(set) var findFriendsContainer: UIView!
    fileprivate var bottomInset: CGFloat
    fileprivate var navBarTitle: String!
    fileprivate var fieldPlaceholderText: String!
    fileprivate var isSearchView: Bool
    open var hasBackButton: Bool = true {
        didSet {
            setupNavigationItems()
        }
    }
    open var gridListItem: UIBarButtonItem?
    open var hasGridViewToggle: Bool = true {
        didSet {
            setupNavigationItems()
        }
    }
    open let navigationItem = UINavigationItem()

    fileprivate var btnWidth: CGFloat {
        get {
            return (searchControlsContainer.bounds.size.width - 2 * Size.containerMargin) / 2
        }
    }
    fileprivate var buttonY: CGFloat {
        get {
            return searchControlsContainer.frame.size.height - 43
        }
    }
    weak open var delegate: SearchScreenDelegate?

// MARK: init

    public init(frame: CGRect, isSearchView: Bool, navBarTitle: String = InterfaceString.Search.Title, fieldPlaceholderText: String = InterfaceString.Search.Prompt) {
        debounced = debounce(0.8)
        bottomInset = 0
        self.navBarTitle = navBarTitle
        self.fieldPlaceholderText = fieldPlaceholderText
        self.isSearchView = isSearchView
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        setupStreamView()
        setupSearchContainer()
        setupNavigationBar()
        setupSearchField()
        if self.isSearchView { setupToggleButtons() }
        setupFindFriendsButton()
        findFriendsContainer.isHidden = !self.isSearchView
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func showNavBars() {
        animate(animated: true) {
            self.searchControlsContainer.frame.origin.y = 64
            self.streamViewContainer.frame = self.getStreamViewFrame()
        }
    }

    open func hideNavBars() {
        animate(animated: true) {
            self.searchControlsContainer.frame.origin.y = 0
            self.streamViewContainer.frame = self.getStreamViewFrame()
        }
    }

// MARK: views

    fileprivate func setupNavigationBar() {
        let frame = CGRect(x: 0, y: 0, width: self.frame.width, height: ElloNavigationBar.Size.height)
        navigationBar.frame = frame
        navigationBar.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        self.addSubview(navigationBar)

        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(SearchScreen.activateSearchField))
        navigationBar.addGestureRecognizer(gesture)

        setupNavigationItems()
    }

    fileprivate func setupSearchContainer() {
        searchControlsContainer.backgroundColor = .white
        searchControlsContainer.frame = frame.atY(64).withHeight(50).withWidth(frame.size.width)
        searchControlsContainer.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        addSubview(searchControlsContainer)
    }

    func activateSearchField() {
        _ = searchField.becomeFirstResponder()
    }

    // TODO: this should be moved into SearchViewController.loadView (and use elloNavigationItem)
    fileprivate func setupNavigationItems() {
        navigationItem.title = navBarTitle

        if hasBackButton {
            let backItem = UIBarButtonItem.backChevronWithTarget(self, action: #selector(SearchScreen.backTapped))
            navigationItem.leftBarButtonItems = [backItem]
            navigationItem.fixNavBarItemPadding()
        }
        else {
            let closeItem = UIBarButtonItem.closeButton(target: self, action: #selector(SearchScreen.backTapped))
            navigationItem.leftBarButtonItems = [closeItem]
        }

        if let gridListItem = gridListItem, hasGridViewToggle {
            navigationItem.rightBarButtonItems = [gridListItem]
        }
        else {
            navigationItem.rightBarButtonItems = []
        }

        navigationBar.items = [navigationItem]
    }

    fileprivate func setupSearchField() {
        searchField.frame = CGRect(x: Size.containerMargin, y: 0, width: searchControlsContainer.frame.size.width - 2 * Size.containerMargin, height: searchControlsContainer.frame.size.height - 10)
        searchField.clearButtonMode = .whileEditing
        searchField.font = UIFont.defaultBoldFont(18)
        searchField.textColor = UIColor.black
        searchField.attributedPlaceholder = NSAttributedString(string: "  \(fieldPlaceholderText)", attributes: [NSForegroundColorAttributeName: UIColor.greyA()])
        searchField.autocapitalizationType = .none
        searchField.autocorrectionType = .no
        searchField.spellCheckingType = .no
        searchField.enablesReturnKeyAutomatically = true
        searchField.returnKeyType = .search
        searchField.keyboardAppearance = .dark
        searchField.keyboardType = .default
        searchField.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(SearchScreen.searchFieldDidChange), for: .editingChanged)
        searchControlsContainer.addSubview(searchField)

        let lineFrame = searchField.frame.fromBottom().grow(up: 1)
        let lineView = UIView(frame: lineFrame)
        lineView.backgroundColor = UIColor.greyA()
        searchControlsContainer.addSubview(lineView)
    }

    fileprivate func setupToggleButtons() {
        searchControlsContainer.frame.size.height += 43
        postsToggleButton.frame = CGRect(x: Size.containerMargin, y: buttonY, width: btnWidth, height: 33)
        postsToggleButton.setTitle(InterfaceString.Search.Posts, for: .normal)
        postsToggleButton.addTarget(self, action: #selector(SearchScreen.onPostsTapped), for: .touchUpInside)
        searchControlsContainer.addSubview(postsToggleButton)

        peopleToggleButton.frame = CGRect(x: postsToggleButton.frame.maxX, y: buttonY, width: btnWidth, height: 33)
        peopleToggleButton.setTitle(InterfaceString.Search.People, for: .normal)
        peopleToggleButton.addTarget(self, action: #selector(SearchScreen.onPeopleTapped), for: .touchUpInside)
        searchControlsContainer.addSubview(peopleToggleButton)

        onPostsTapped()
    }

    open func onPostsTapped() {
        postsToggleButton.isSelected = true
        peopleToggleButton.isSelected = false
        var searchFieldText = searchField.text ?? ""
        if searchFieldText == "@" {
            searchFieldText = ""
        }
        searchField.text = searchFieldText
        delegate?.toggleChanged(searchFieldText, isPostSearch: postsToggleButton.isSelected)
    }

    open func onPeopleTapped() {
        peopleToggleButton.isSelected = true
        postsToggleButton.isSelected = false
        var searchFieldText = searchField.text ?? ""
        if searchFieldText == "" {
            searchFieldText = "@"
        }
        searchField.text = searchFieldText
        delegate?.toggleChanged(searchFieldText, isPostSearch: postsToggleButton.isSelected)
    }

    fileprivate func setupStreamView() {
        streamViewContainer.frame = getStreamViewFrame()
        streamViewContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        streamViewContainer.backgroundColor = .white
        self.addSubview(streamViewContainer)
    }

    fileprivate func getStreamViewFrame() -> CGRect {
        return bounds
    }

    fileprivate func setupFindFriendsButton() {
        let height = CGFloat(143)
        let containerFrame = self.frame.fromBottom().grow(up: height)
        findFriendsContainer = UIView(frame: containerFrame)
        findFriendsContainer.backgroundColor = .black
        findFriendsContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]

        let margins = UIEdgeInsets(top: 20, left: 15, bottom: 26, right: 15)
        let buttonHeight = CGFloat(50)
        let button = StyledButton(style: .White)
        button.frame = CGRect(
            x: margins.left,
            y: containerFrame.height - margins.bottom - buttonHeight,
            width: containerFrame.width - margins.left - margins.right,
            height: buttonHeight
            )
        button.setTitle(InterfaceString.Friends.FindAndInvite, for: .normal)
        button.addTarget(self, action: #selector(findFriendsTapped), for: .touchUpInside)
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let label = StyledLabel(style: .White)
        label.frame = CGRect(
            x: margins.left, y: 0,
            width: button.frame.width,
            height: containerFrame.height - margins.bottom - button.frame.height
        )
        label.numberOfLines = 2
        label.text = InterfaceString.Search.FindFriendsPrompt
        label.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]

        self.addSubview(findFriendsContainer)
        findFriendsContainer.addSubview(label)
        findFriendsContainer.addSubview(button)
    }

    open func viewForStream() -> UIView {
        return streamViewContainer
    }

    fileprivate func clearSearch() {
        delegate?.searchFieldCleared()
        debounced {}
    }

    open func updateInsets(bottom: CGFloat) {
        bottomInset = bottom
        setNeedsLayout()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        findFriendsContainer.frame.origin.y = frame.size.height - findFriendsContainer.frame.height - bottomInset - ElloTabBar.Size.height
        postsToggleButton.frame = CGRect(x: Size.containerMargin, y: buttonY, width: btnWidth, height: 33)
        peopleToggleButton.frame = CGRect(x: postsToggleButton.frame.maxX, y: buttonY, width: btnWidth, height: 33)
    }

    open func searchForText() {
        let text = searchField.text ?? ""
        if text.characters.count == 0 { return }
        hideFindFriends()
        delegate?.searchFieldChanged(text, isPostSearch: postsToggleButton.isSelected)
    }

// MARK: actions

    @objc
    func backTapped() {
        delegate?.searchCanceled()
    }

    @objc
    func findFriendsTapped() {
        delegate?.findFriendsTapped()
    }

    @objc
    func searchFieldDidChange() {
        delegate?.searchShouldReset()
        let text = searchField.text ?? ""
        if text.characters.count == 0 {
            clearSearch()
            showFindFriends()
        }
        else {
            debounced { [unowned self] in
                self.searchForText()
            }
        }
    }

}

extension SearchScreen: UITextFieldDelegate {

    @objc
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        clearSearch()
        showFindFriends()
        return true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = textField.resignFirstResponder()
        return true
    }

}

extension SearchScreen {

    fileprivate func showFindFriends() {
        findFriendsContainer.isHidden = !isSearchView
    }

    fileprivate func hideFindFriends() {
        findFriendsContainer.isHidden = true
    }

}
