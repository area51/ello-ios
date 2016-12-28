////
///  CategoryViewController.swift
//

public final class CategoryViewController: StreamableViewController {

    var mockScreen: CategoryScreenProtocol?
    public var screen: CategoryScreenProtocol {
        return mockScreen ?? self.view as! CategoryScreenProtocol
    }

    var gridListItem: UIBarButtonItem?
    var category: Category?
    var slug: String
    var allCategories: [Category] = []
    var pagePromotional: PagePromotional?
    var categoryPromotional: Promotional?
    var generator: CategoryGenerator?
    var userDidScroll: Bool = false

    public init(slug: String, name: String? = nil) {
        self.slug = slug
        super.init(nibName: nil, bundle: nil)
        self.title = name
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        self.title = category?.name ?? DiscoverType.fromURL(slug)?.name

        let screen = CategoryScreen()
        screen.navigationItem = elloNavigationItem

        self.view = screen
        viewContainer = screen.streamContainer
        screen.delegate = self
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItems()
        let streamKind: StreamKind
        if let type = DiscoverType.fromURL(slug) {
            streamKind = .discover(type: type)
        }
        else {
            streamKind = .category(slug: slug)
        }
        streamViewController.streamKind = streamKind
        gridListItem?.setImage(isGridView: streamKind.isGridView)

        self.generator = CategoryGenerator(
            slug: slug,
            currentUser: currentUser,
            streamKind: streamKind,
            destination: self
        )

        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.initialLoadClosure = { [unowned self] in self.loadCategory() }
        streamViewController.reloadClosure = { [unowned self] in self.reloadEntireCategory() }
        streamViewController.toggleClosure = { [unowned self] isGridView in self.toggleGrid(isGridView) }

        streamViewController.loadInitialPage()
    }

    fileprivate func updateInsets() {
        updateInsets(navBar: screen.topInsetView, streamController: streamViewController)

        if !userDidScroll && screen.categoryCardsVisible {
            var offset: CGFloat = CategoryCardListView.Size.height
            if tabBarVisible() {
                offset += ElloNavigationBar.Size.height
            }
            streamViewController.collectionView.setContentOffset(CGPoint(x: 0, y: -offset), animated: true)
        }
    }

    override func showNavBars(_ scrollToBottom: Bool) {
        super.showNavBars(scrollToBottom)
        positionNavBar(screen.navigationBar, visible: true, withConstraint: screen.navigationBarTopConstraint)
        screen.animateCategoriesList(navBarVisible: true)
        updateInsets()

        if scrollToBottom {
            self.scrollToBottom(streamViewController)
        }
    }

    override func hideNavBars() {
        super.hideNavBars()
        positionNavBar(screen.navigationBar, visible: false, withConstraint: screen.navigationBarTopConstraint, animated: true)
        screen.animateCategoriesList(navBarVisible: false)
        updateInsets()
    }

    func toggleGrid(_ isGridView: Bool) {
        generator?.toggleGrid()
    }

    override public func streamViewWillBeginDragging(scrollView: UIScrollView) {
        super.streamViewWillBeginDragging(scrollView: scrollView)
        userDidScroll = true
    }
}

private extension CategoryViewController {

    func setupNavigationItems() {
        let backItem = UIBarButtonItem.backChevron(withController: self)
        elloNavigationItem.leftBarButtonItems = [backItem]
        elloNavigationItem.fixNavBarItemPadding()

        let searchItem = UIBarButtonItem.searchItem(controller: self)
        let gridListItem = UIBarButtonItem.gridListItem(delegate: streamViewController, isGridView: streamViewController.streamKind.isGridView)
        self.gridListItem = gridListItem
        let rightBarButtonItems = [searchItem, gridListItem]
        if !elloNavigationItem.areRightButtonsTheSame(rightBarButtonItems) {
            elloNavigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }

    func loadCategory() {
        generator?.load()
    }

    func reloadEntireCategory() {
        pagePromotional = nil
        categoryPromotional = nil
        category?.randomPromotional = nil
        generator?.load(reload: true)
    }
}

// MARK: CategoryViewController: StreamDestination
extension CategoryViewController: CategoryStreamDestination, StreamDestination {

    public var pagingEnabled: Bool {
        get { return streamViewController.pagingEnabled }
        set { streamViewController.pagingEnabled = newValue }
    }

    public func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping ElloEmptyCompletion) {
        streamViewController.replacePlaceholder(type, with: items, completion: completion)
        updateInsets()
    }

    public func setPlaceholders(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad()
        streamViewController.appendUnsizedCellItems(items, withWidth: view.frame.width) { _ in }
    }

    public func setPrimary(jsonable: JSONAble) {
        if let category = jsonable as? Category {
            self.category = category

            if let categoryPromotional = self.categoryPromotional {
                category.randomPromotional = categoryPromotional
            }
            else {
                categoryPromotional = category.randomPromotional
            }

            self.title = category.name
        }
        else if let pagePromotional = jsonable as? PagePromotional {
            self.pagePromotional = pagePromotional
        }
        updateInsets()
    }

    public func set(categories: [Category]) {
        allCategories = categories

        let shouldAnimate = !screen.categoryCardsVisible
        let info = allCategories.map { (category: Category) -> CategoryCardListView.CategoryInfo in
            return CategoryCardListView.CategoryInfo(title: category.name, imageURL: category.tileURL)
        }

        let pullToRefreshView = streamViewController.pullToRefreshView
        pullToRefreshView?.isHidden = true
        screen.set(categoriesInfo: info, animated: shouldAnimate) {
            pullToRefreshView?.isHidden = false
        }

        let selectedCategoryIndex = allCategories.index { $0.slug == slug }
        if let selectedCategoryIndex = selectedCategoryIndex, shouldAnimate {
            screen.scrollToCategory(index: selectedCategoryIndex)
            screen.selectCategory(index: selectedCategoryIndex)
        }
        updateInsets()
    }

    public func primaryJSONAbleNotFound() {
        self.streamViewController.doneLoading()
    }

    public func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }
}

extension CategoryViewController: CategoryScreenDelegate {

    public func selectCategoryFor(slug: String) {
        guard let category = categoryFor(slug: slug) else { return }
        select(category: category)
    }

    fileprivate func categoryFor(slug: String) -> Category? {
        return allCategories.find { $0.slug == slug }
    }

    public func categorySelected(index: Int) {
        guard
            let category = allCategories.safeValue(index), category.id != self.category?.id
        else { return }
        screen.selectCategory(index: index)
        select(category: category)
    }

    public func select(category: Category) {
		Tracker.sharedTracker.categoryOpened(category.slug)

        var kind: StreamKind?
        switch category.level {
        case .meta:
            if let type = DiscoverType.fromURL(category.slug) {
                kind = .discover(type: type)
            }
        default:
            kind = .category(slug: category.slug)
        }

        guard let streamKind = kind else { return }

        category.randomPromotional = nil
        streamViewController.streamKind = streamKind
        gridListItem?.setImage(isGridView: streamKind.isGridView)
        generator?.reset(streamKind: streamKind, category: category, pagePromotional: nil)
        self.category = category
        self.slug = category.slug
        self.title = category.name
        reloadEntireCategory()
    }
}
