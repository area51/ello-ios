////
///  PostbarController.swift
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
// Xcode modifies these regardless of changing them
// swiftlint:disable colon
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

// swiftlint:enable colon
public protocol PostbarDelegate: class {
    func viewsButtonTapped(_ indexPath: IndexPath)
    func commentsButtonTapped(_ cell: StreamFooterCell, imageLabelControl: ImageLabelControl)
    func deleteCommentButtonTapped(_ indexPath: IndexPath)
    func editCommentButtonTapped(_ indexPath: IndexPath)
    func lovesButtonTapped(_ cell: StreamFooterCell?, indexPath: IndexPath)
    func repostButtonTapped(_ indexPath: IndexPath)
    func shareButtonTapped(_ indexPath: IndexPath, sourceView: UIView)
    func flagCommentButtonTapped(_ indexPath: IndexPath)
    func replyToCommentButtonTapped(_ indexPath: IndexPath)
    func replyToAllButtonTapped(_ indexPath: IndexPath)
    func watchPostTapped(_ watching: Bool, cell: StreamCreateCommentCell, indexPath: IndexPath)
}

open class PostbarController: PostbarDelegate {

    weak var presentingController: StreamViewController?
    open var collectionView: UICollectionView
    open let dataSource: StreamDataSource
    open var currentUser: User?

    // on the post detail screen, the comments don't show/hide
    var toggleableComments: Bool = true

    public init(collectionView: UICollectionView, dataSource: StreamDataSource, presentingController: StreamViewController) {
        self.collectionView = collectionView
        self.dataSource = dataSource
        self.presentingController = presentingController
    }

    // MARK:

    open func viewsButtonTapped(_ indexPath: IndexPath) {
        if let post = postForIndexPath(indexPath) {
            Tracker.sharedTracker.viewsButtonTapped(post: post)
            // This is a bit dirty, we should not call a method on a compositionally held
            // controller's postTappedDelegate. Need to chat about this with the crew.
            presentingController?.postTappedDelegate?.postTapped(post)
        }
    }

    open func commentsButtonTapped(_ cell: StreamFooterCell, imageLabelControl: ImageLabelControl) {
        guard !dataSource.streamKind.isGridView else {
            cell.cancelCommentLoading()
            if let indexPath = collectionView.indexPath(for: cell) {
                self.viewsButtonTapped(indexPath)
            }
            return
        }

        guard !dataSource.streamKind.isDetail else {
            return
        }

        guard toggleableComments else {
            cell.cancelCommentLoading()
            return
        }

        if let indexPath = collectionView.indexPath(for: cell),
            let item = dataSource.visibleStreamCellItem(at: indexPath),
            let post = item.jsonable as? Post
        {
            imageLabelControl.isSelected = cell.commentsOpened
            cell.commentsControl.isEnabled = false

            if !cell.commentsOpened {
                _ = self.dataSource.removeCommentsFor(post: post)
                self.collectionView.reloadData()
                item.state = .collapsed
                imageLabelControl.isEnabled = true
                imageLabelControl.finishAnimation()
                imageLabelControl.isHighlighted = false
            }
            else {
                item.state = .loading
                imageLabelControl.isHighlighted = true
                imageLabelControl.animate()
                let streamService = StreamService()
                streamService.loadMoreCommentsForPost(
                    post.id,
                    streamKind: dataSource.streamKind,
                    success: { (comments, responseConfig) in
                        if let updatedIndexPath = self.dataSource.indexPathForItem(item) {
                            item.state = .expanded
                            imageLabelControl.finishAnimation()
                            let nextIndexPath = IndexPath(item: updatedIndexPath.row + 1, section: updatedIndexPath.section)
                            self.commentLoadSuccess(post, comments: comments, indexPath: nextIndexPath, cell: cell)
                        }
                    },
                    failure: { _ in
                        item.state = .collapsed
                        imageLabelControl.finishAnimation()
                        cell.cancelCommentLoading()
                        print("comment load failure")
                    },
                    noContent: {
                        item.state = .expanded
                        imageLabelControl.finishAnimation()
                        if let updatedIndexPath = self.dataSource.indexPathForItem(item) {
                            let nextIndexPath = IndexPath(item: updatedIndexPath.row + 1, section: updatedIndexPath.section)
                            self.commentLoadSuccess(post, comments: [], indexPath: nextIndexPath, cell: cell)
                        }
                    })
            }
        }
        else {
            cell.cancelCommentLoading()
        }
    }

    open func deleteCommentButtonTapped(_ indexPath: IndexPath) {
        let message = InterfaceString.Post.DeleteCommentConfirm
        let alertController = AlertViewController(message: message)

        let yesAction = AlertAction(title: InterfaceString.Yes, style: .dark) {
            action in
            if let comment = self.commentForIndexPath(indexPath) {
                // comment deleted
                postNotification(CommentChangedNotification, value: (comment, .delete))
                // post comment count updated
                ContentChange.updateCommentCount(comment, delta: -1)
                PostService().deleteComment(comment.postId, commentId: comment.id,
                    success: {},
                    failure: { (error, statusCode)  in
                        // TODO: add error handling
                        print("failed to delete comment, error: \(error.elloErrorMessage ?? error.localizedDescription)")
                    })
            }
        }
        let noAction = AlertAction(title: InterfaceString.No, style: .light, handler: .none)

        alertController.addAction(yesAction)
        alertController.addAction(noAction)

        logPresentingAlert(presentingController?.readableClassName() ?? "PostbarController")
        presentingController?.present(alertController, animated: true, completion: .none)
    }

    open func editCommentButtonTapped(_ indexPath: IndexPath) {
        // This is a bit dirty, we should not call a method on a compositionally held
        // controller's createPostDelegate. Can this use the responder chain when we have
        // parameters to pass?
        if let comment = self.commentForIndexPath(indexPath),
            let presentingController = presentingController
        {
            presentingController.createPostDelegate?.editComment(comment, fromController: presentingController)
        }
    }

    open func lovesButtonTapped(_ cell: StreamFooterCell?, indexPath: IndexPath) {
        if let post = self.postForIndexPath(indexPath) {
            Tracker.sharedTracker.postLoved(post)
            cell?.lovesControl.isUserInteractionEnabled = false
            if post.loved { unlovePost(post, cell: cell) }
            else { lovePost(post, cell: cell) }
        }
    }

    fileprivate func unlovePost(_ post: Post, cell: StreamFooterCell?) {
        Tracker.sharedTracker.postUnloved(post)
        if let count = post.lovesCount {
            post.lovesCount = count - 1
            post.loved = false
            postNotification(PostChangedNotification, value: (post, .loved))
        }
        if let user = currentUser, let userLoveCount = user.lovesCount {
            user.lovesCount = userLoveCount - 1
            postNotification(CurrentUserChangedNotification, value: user)
        }
        let service = LovesService()
        service.unlovePost(
            postId: post.id,
            success: {
                cell?.lovesControl.isUserInteractionEnabled = true
            },
            failure: { error, statusCode in
                cell?.lovesControl.isUserInteractionEnabled = true
                print("failed to unlove post \(post.id), error: \(error.elloErrorMessage ?? error.localizedDescription)")
            })
    }

    fileprivate func lovePost(_ post: Post, cell: StreamFooterCell?) {
        Tracker.sharedTracker.postLoved(post)
        if let count = post.lovesCount {
            post.lovesCount = count + 1
            post.loved = true
            postNotification(PostChangedNotification, value: (post, .loved))
        }
        if let user = currentUser, let userLoveCount = user.lovesCount {
            user.lovesCount = userLoveCount + 1
            postNotification(CurrentUserChangedNotification, value: user)
        }
        LovesService().lovePost(
            postId: post.id,
            success: { (love, responseConfig) in
                postNotification(JSONAbleChangedNotification, value: (love, .create))
                cell?.lovesControl.isUserInteractionEnabled = true
            },
            failure: { error, statusCode in
                cell?.lovesControl.isUserInteractionEnabled = true
                print("failed to love post \(post.id), error: \(error.elloErrorMessage ?? error.localizedDescription)")
            })
    }

    open func repostButtonTapped(_ indexPath: IndexPath) {
        if let post = self.postForIndexPath(indexPath) {
            Tracker.sharedTracker.postReposted(post)
            let message = InterfaceString.Post.RepostConfirm
            let alertController = AlertViewController(message: message)
            alertController.autoDismiss = false

            let yesAction = AlertAction(title: InterfaceString.Yes, style: .dark) { action in
                self.createRepost(post, alertController: alertController)
            }
            let noAction = AlertAction(title: InterfaceString.No, style: .light) { action in
                alertController.dismiss()
            }

            alertController.addAction(yesAction)
            alertController.addAction(noAction)

            logPresentingAlert(presentingController?.readableClassName() ?? "PostbarController")
            presentingController?.present(alertController, animated: true, completion: .none)
        }
    }

    fileprivate func createRepost(_ post: Post, alertController: AlertViewController)
    {
        alertController.resetActions()
        alertController.dismissable = false

        let spinnerContainer = UIView(frame: CGRect(x: 0, y: 0, width: alertController.view.frame.size.width, height: 200))
        let spinner = ElloLogoView(frame: CGRect(origin: .zero, size: ElloLogoView.Size.Natural))
        spinner.center = spinnerContainer.bounds.center
        spinnerContainer.addSubview(spinner)
        alertController.contentView = spinnerContainer
        spinner.animateLogo()
        if let user = currentUser, let userPostsCount = user.postsCount {
            user.postsCount = userPostsCount + 1
            postNotification(CurrentUserChangedNotification, value: user)
        }
        RePostService().repost(post: post,
            success: { repost in
                postNotification(PostChangedNotification, value: (repost, .create))
                alertController.contentView = nil
                alertController.message = InterfaceString.Post.RepostSuccess
                delay(1) {
                    alertController.dismiss()
                }
            }, failure: { (error, statusCode)  in
                alertController.contentView = nil
                alertController.message = InterfaceString.Post.RepostError
                alertController.autoDismiss = true
                alertController.dismissable = true
                let okAction = AlertAction(title: InterfaceString.OK, style: .light, handler: .none)
                alertController.addAction(okAction)
            })
    }

    open func shareButtonTapped(_ indexPath: IndexPath, sourceView: UIView) {
        if let post = dataSource.postForIndexPath(indexPath),
            let shareLink = post.shareLink,
            let shareURL = URL(string: shareLink)
        {
            Tracker.sharedTracker.postShared(post)
            let activityVC = UIActivityViewController(activityItems: [shareURL], applicationActivities: [SafariActivity()])
            if UI_USER_INTERFACE_IDIOM() == .phone {
                activityVC.modalPresentationStyle = .fullScreen
                logPresentingAlert(presentingController?.readableClassName() ?? "PostbarController")
                presentingController?.present(activityVC, animated: true) { }
            }
            else {
                activityVC.modalPresentationStyle = .popover
                activityVC.popoverPresentationController?.sourceView = sourceView
                logPresentingAlert(presentingController?.readableClassName() ?? "PostbarController")
                presentingController?.present(activityVC, animated: true) { }
            }
        }
    }

    open func flagCommentButtonTapped(_ indexPath: IndexPath) {
        if let comment = commentForIndexPath(indexPath),
            let presentingController = presentingController
        {
            let flagger = ContentFlagger(
                presentingController: presentingController,
                flaggableId: comment.id,
                contentType: .comment,
                commentPostId: comment.postId
            )

            flagger.displayFlaggingSheet()
        }
    }

    open func replyToCommentButtonTapped(_ indexPath: IndexPath) {
        if let comment = commentForIndexPath(indexPath) {
            // This is a bit dirty, we should not call a method on a compositionally held
            // controller's createPostDelegate. Can this use the responder chain when we have
            // parameters to pass?
            if let presentingController = presentingController,
                let post = comment.loadedFromPost,
                let atName = comment.author?.atName
            {
                presentingController.createPostDelegate?.createComment(post, text: "\(atName) ", fromController: presentingController)
            }
        }
    }

    open func replyToAllButtonTapped(_ indexPath: IndexPath) {
        // This is a bit dirty, we should not call a method on a compositionally held
        // controller's createPostDelegate. Can this use the responder chain when we have
        // parameters to pass?
        if let comment = commentForIndexPath(indexPath),
            let presentingController = presentingController,
            let post = comment.loadedFromPost
        {
            PostService().loadReplyAll(post.id, success: { usernames in
                let usernamesText = usernames.reduce("") { memo, username in
                    return memo + "@\(username) "
                }
                presentingController.createPostDelegate?.createComment(post, text: usernamesText, fromController: presentingController)
            }, failure: {
                presentingController.createCommentTapped(post)
            })
        }
    }

    open func watchPostTapped(_ watching: Bool, cell: StreamCreateCommentCell, indexPath: IndexPath) {
        guard let
            comment = dataSource.commentForIndexPath(indexPath),
            let post = comment.parentPost
        else { return }

        cell.watching = watching
        cell.isUserInteractionEnabled = false
        PostService().toggleWatchPost(post, watching: watching)
            .onSuccess { post in
                cell.isUserInteractionEnabled = true
                postNotification(PostChangedNotification, value: (post, .watching))
            }
            .onFail { error in
                cell.isUserInteractionEnabled = true
                cell.watching = !watching
            }
    }

// MARK: - Private

    fileprivate func postForIndexPath(_ indexPath: IndexPath) -> Post? {
        return dataSource.postForIndexPath(indexPath)
    }

    fileprivate func commentForIndexPath(_ indexPath: IndexPath) -> ElloComment? {
        return dataSource.commentForIndexPath(indexPath)
    }

    fileprivate func commentLoadSuccess(_ post: Post, comments jsonables: [JSONAble], indexPath: IndexPath, cell: StreamFooterCell) {
        self.appendCreateCommentItem(post, at: indexPath)
        let commentsStartingIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)

        var items = StreamCellItemParser().parse(jsonables, streamKind: StreamKind.following, currentUser: currentUser)

        if let currentUser = currentUser {
            let newComment = ElloComment.newCommentForPost(post, currentUser: currentUser)
            if post.commentsCount > ElloAPI.postComments(postId: "").parameters!["per_page"] as? Int {
                items.append(StreamCellItem(jsonable: jsonables.last ?? newComment, type: .seeMoreComments))
            }
            else {
                items.append(StreamCellItem(jsonable: newComment, type: .spacer(height: 10.0)))
            }
        }

        self.dataSource.insertUnsizedCellItems(items,
            withWidth: self.collectionView.frame.width,
            startingIndexPath: commentsStartingIndexPath) { (indexPaths) in
                self.collectionView.reloadData() // insertItemsAtIndexPaths(indexPaths)
                cell.commentsControl.isEnabled = true

                if indexPaths.count == 1 && jsonables.count == 0 {
                    self.presentingController?.createCommentTapped(post)
                }
            }
    }

    fileprivate func appendCreateCommentItem(_ post: Post, at indexPath: IndexPath) {
        if let currentUser = currentUser {
            let comment = ElloComment.newCommentForPost(post, currentUser: currentUser)
            let createCommentItem = StreamCellItem(jsonable: comment, type: .createComment)

            let items = [createCommentItem]
            self.dataSource.insertStreamCellItems(items, startingIndexPath: indexPath)
            self.collectionView.reloadData() // insertItemsAtIndexPaths([indexPath]) //
        }
    }

    fileprivate func commentLoadFailure(_ error: NSError, statusCode: Int?) {
    }

}
