////
///  CategoryGenerator.swift
//

public protocol CategoryStreamDestination: StreamDestination {
    func set(categories: [Category])
}

public final class CategoryGenerator: StreamGenerator {

    public var currentUser: User?
    public var streamKind: StreamKind
    weak fileprivate var categoryStreamDestination: CategoryStreamDestination?
    weak public var destination: StreamDestination? {
        get { return categoryStreamDestination }
        set {
            if !(newValue is CategoryStreamDestination) { fatalError("CategoryGenerator.destination must conform to CategoryStreamDestination") }
            categoryStreamDestination = newValue as? CategoryStreamDestination
        }
    }

    fileprivate var category: Category?
    fileprivate var categories: [Category]?
    fileprivate var slug: String
    fileprivate var pagePromotional: PagePromotional?
    fileprivate var posts: [Post]?
    fileprivate var hasPosts: Bool?
    fileprivate var localToken: String!
    fileprivate var loadingToken = LoadingToken()

    fileprivate let queue = OperationQueue()

    func headerItems() -> [StreamCellItem] {
        var items: [StreamCellItem] = []

        if usesPagePromo() {
            if let pagePromotional = pagePromotional {
                items += [StreamCellItem(jsonable: pagePromotional, type: .pagePromotionalHeader)]
            }
        }
        else if let category = self.category, category.hasPromotionalData {
            items += [StreamCellItem(jsonable: category, type: .categoryPromotionalHeader)]
        }

        return items
    }

    public init(slug: String,
                currentUser: User?,
                streamKind: StreamKind,
                destination: StreamDestination?
        ) {
        self.slug = slug
        self.currentUser = currentUser
        self.streamKind = streamKind
        self.localToken = loadingToken.resetInitialPageLoadingToken()
        self.destination = destination
    }

    public func reset(streamKind: StreamKind, category: Category, pagePromotional: PagePromotional?) {
        self.streamKind = streamKind
        self.category = category
        self.slug = category.slug
        self.pagePromotional = nil
    }

    public func load(reload: Bool = false) {
        if reload {
            pagePromotional = nil
        }

        let doneOperation = AsyncOperation()
        queue.addOperation(doneOperation)

        localToken = loadingToken.resetInitialPageLoadingToken()
        setPlaceHolders()
        setInitialJSONAble(doneOperation)
        loadCategories()
        loadCategory(doneOperation, reload: reload)
        if usesPagePromo() {
            loadPagePromotional(doneOperation)
        }
        loadCategoryPosts(doneOperation)
    }

    public func toggleGrid() {
        guard let posts = posts else { return }
        destination?.replacePlaceholder(type: .categoryPosts, items: parse(jsonables: posts)) {}
    }

}

private extension CategoryGenerator {

    func setPlaceHolders() {
        destination?.setPlaceholders(items: [
            StreamCellItem(type: .placeholder, placeholderType: .categoryHeader),
            StreamCellItem(type: .placeholder, placeholderType: .categoryPosts)
        ])
    }

    func setInitialJSONAble(_ doneOperation: AsyncOperation) {
        guard let category = category else { return }

        let jsonable: JSONAble?
        if usesPagePromo() {
            jsonable = pagePromotional
        }
        else {
            jsonable = category
        }

        if let jsonable = jsonable {
            destination?.setPrimary(jsonable: jsonable)
            destination?.replacePlaceholder(type: .categoryHeader, items: headerItems()) {}
            doneOperation.run()
        }
    }

    func usesPagePromo() -> Bool {
        let discoverType = DiscoverType.fromURL(slug)
        // discover types are featured/trending/recent, they always use a page promo
        guard discoverType == nil else {
            return true
        }

        guard let category = category else {
            return false
        }

        return category.usesPagePromo
    }

    func loadCategory(_ doneOperation: AsyncOperation, reload: Bool = false) {
        guard !doneOperation.isFinished || reload else { return }
        guard !usesPagePromo() else { return }

        CategoryService().loadCategory(slug)
            .onSuccess { [weak self] category in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }
                sself.category = category
                sself.destination?.setPrimary(jsonable: category)
                sself.destination?.replacePlaceholder(type: .categoryHeader, items: sself.headerItems()) {}
                doneOperation.run()
            }
            .onFail { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
            }
    }

    func loadPagePromotional(_ doneOperation: AsyncOperation) {
        guard usesPagePromo() else { return }

        PagePromotionalService().loadPagePromotionals()
            .onSuccess { [weak self] promotionals in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                if let pagePromotional = promotionals?.randomItem() {
                    sself.pagePromotional = pagePromotional
                    sself.destination?.setPrimary(jsonable: pagePromotional)
                }
                sself.destination?.replacePlaceholder(type: .categoryHeader, items: sself.headerItems()) {}
                doneOperation.run()
            }
            .onFail { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        }
    }

    func loadCategories() {
        CategoryService().loadCategories()
            .onSuccess { [weak self] categories in
                guard let sself = self else { return }
                sself.categories = categories
                sself.categoryStreamDestination?.set(categories: categories)
            }.ignoreFailures()
    }

    func loadCategoryPosts(_ doneOperation: AsyncOperation) {
        let displayPostsOperation = AsyncOperation()
        displayPostsOperation.addDependency(doneOperation)
        queue.addOperation(displayPostsOperation)

        self.destination?.replacePlaceholder(type: .categoryPosts, items: [StreamCellItem(type: .streamLoading)]) {}

        var apiEndpoint: ElloAPI?
        if usesPagePromo() {
            guard let discoverType = DiscoverType.fromURL(slug) else { return }
            apiEndpoint = .discover(type: discoverType)
        }
        else {
            apiEndpoint = .categoryPosts(slug: slug)
        }

        guard let endpoint = apiEndpoint else { return }

        StreamService().loadStream(
            endpoint: endpoint,
            streamKind: streamKind,
            success: { [weak self] (jsonables, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                sself.destination?.setPagingConfig(responseConfig: responseConfig)
                sself.posts = jsonables as? [Post]
                let items = sself.parse(jsonables: jsonables)
                displayPostsOperation.run {
                    inForeground {
                        if items.count == 0 {
                            sself.hasPosts = false
                            let noItems = [StreamCellItem(type: .noPosts)]
                            sself.destination?.replacePlaceholder(type: .categoryPosts, items: noItems) {
                                sself.destination?.pagingEnabled = false
                            }
                            sself.destination?.replacePlaceholder(type: .categoryHeader, items: sself.headerItems()) {}
                        }
                        else {
                            sself.destination?.replacePlaceholder(type: .categoryPosts, items: items) {
                                sself.destination?.pagingEnabled = true
                            }
                        }
                    }
                }
            }, failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
            }, noContent: { [weak self] in
                guard let sself = self else { return }
                let noContentItem = StreamCellItem(type: .emptyStream(height: 282))
                sself.destination?.replacePlaceholder(type: .categoryPosts, items: [noContentItem]) {}
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        })
    }
}
