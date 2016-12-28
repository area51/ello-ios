////
///  ProfileGenerator.swift
//

public final class ProfileGenerator: StreamGenerator {

    public var currentUser: User?
    public var streamKind: StreamKind
    weak public var destination: StreamDestination?

    fileprivate var user: User?
    fileprivate let userParam: String
    fileprivate var posts: [Post]?
    fileprivate var hasPosts: Bool?
    fileprivate var localToken: String!
    fileprivate var loadingToken = LoadingToken()

    fileprivate let queue = OperationQueue()

    func headerItems() -> [StreamCellItem] {
        guard let user = user else { return [] }

        var items = [
            StreamCellItem(jsonable: user, type: .profileHeader),
        ]
        if hasPosts != false {
            items += [
                StreamCellItem(jsonable: user, type: .fullWidthSpacer(height: 5))
            ]
        }
        return items
    }

    public init(
        currentUser: User?,
        userParam: String,
        user: User?,
        streamKind: StreamKind,
        destination: StreamDestination?
        ) {
        self.currentUser = currentUser
        self.user = user
        self.userParam = userParam
        self.streamKind = streamKind
        self.localToken = loadingToken.resetInitialPageLoadingToken()
        self.destination = destination
    }

    public func load(reload: Bool = false) {
        let doneOperation = AsyncOperation()
        queue.addOperation(doneOperation)

        localToken = loadingToken.resetInitialPageLoadingToken()
        setPlaceHolders()
        setInitialUser(doneOperation)
        loadUser(doneOperation, reload: reload)
        loadUserPosts(doneOperation)
    }

    public func toggleGrid() {
        if let posts = posts, hasPosts == true {
            destination?.replacePlaceholder(type: .profilePosts, items: parse(jsonables: posts)) {}
        }
        else if let user = user, hasPosts == false {
            let noItems = [StreamCellItem(jsonable: user, type: .noPosts)]
            destination?.replacePlaceholder(type: .profilePosts, items: noItems) {}
        }
    }

}

private extension ProfileGenerator {

    func setPlaceHolders() {
        let header = StreamCellItem(type: .profileHeaderGhost, placeholderType: .profileHeader)
        header.calculatedCellHeights.oneColumn = ProfileHeaderGhostCell.Size.height
        header.calculatedCellHeights.multiColumn = ProfileHeaderGhostCell.Size.height
        destination?.setPlaceholders(items: [
            header,
            StreamCellItem(type: .placeholder, placeholderType: .profilePosts)
        ])
    }

    func setInitialUser(_ doneOperation: AsyncOperation) {
        guard let user = user else { return }

        destination?.setPrimary(jsonable: user)
        destination?.replacePlaceholder(type: .profileHeader, items: headerItems()) {}
        doneOperation.run()
    }

    func loadUser(_ doneOperation: AsyncOperation, reload: Bool = false) {
        guard !doneOperation.isFinished || reload else { return }

        // load the user with no posts
        StreamService().loadUser(
            streamKind.endpoint,
            streamKind: streamKind,
            success: { [weak self] (user, _) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                sself.user = user
                sself.destination?.setPrimary(jsonable: user)
                sself.destination?.replacePlaceholder(type: .profileHeader, items: sself.headerItems()) {}
                doneOperation.run()
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        })
    }

    func loadUserPosts(_ doneOperation: AsyncOperation) {
        let displayPostsOperation = AsyncOperation()
        displayPostsOperation.addDependency(doneOperation)
        queue.addOperation(displayPostsOperation)

        self.destination?.replacePlaceholder(type: .profilePosts, items: [StreamCellItem(type: .streamLoading)]) {}

        StreamService().loadUserPosts(
            userParam,
            success: { [weak self] (posts, responseConfig) in
                guard let sself = self else { return }
                guard sself.loadingToken.isValidInitialPageLoadingToken(sself.localToken) else { return }

                sself.destination?.setPagingConfig(responseConfig: responseConfig)
                sself.posts = posts
                let userPostItems = sself.parse(jsonables: posts)
                displayPostsOperation.run {
                    inForeground {
                        if userPostItems.count == 0 {
                            sself.hasPosts = false
                            let user: User = sself.user ?? User.empty(id: sself.userParam)
                            let noItems = [StreamCellItem(jsonable: user, type: .noPosts)]
                            sself.destination?.replacePlaceholder(type: .profilePosts, items: noItems) {
                                sself.destination?.pagingEnabled = false
                            }
                            sself.destination?.replacePlaceholder(type: .profileHeader, items: sself.headerItems()) {}
                        }
                        else {
                            let updateHeaderItems = sself.hasPosts == false
                            sself.hasPosts = true
                            if updateHeaderItems {
                                sself.destination?.replacePlaceholder(type: .profileHeader, items: sself.headerItems()) {}
                            }
                            sself.destination?.replacePlaceholder(type: .profilePosts, items: userPostItems) {
                                sself.destination?.pagingEnabled = true
                            }
                        }
                    }
                }
            },
            failure: { [weak self] _ in
                guard let sself = self else { return }
                sself.destination?.primaryJSONAbleNotFound()
                sself.queue.cancelAllOperations()
        })
    }
}
