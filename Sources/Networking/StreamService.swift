////
///  StreamService.swift
//

import Moya

public typealias StreamSuccessCompletion = ([JSONAble], ResponseConfig) -> Void
public typealias UserSuccessCompletion = (User, ResponseConfig) -> Void
public typealias UserPostsSuccessCompletion = ([Post], ResponseConfig) -> Void

public struct StreamLoadedNotifications {
    static let streamLoaded = TypedNotification<StreamKind>(name: "StreamLoadedNotification")
}

open class StreamService {
    public init() {}

    open func loadStream(
        streamKind: StreamKind,
        success: @escaping StreamSuccessCompletion,
        failure: @escaping ElloFailureCompletion = { _ in },
        noContent: @escaping ElloEmptyCompletion = {})
    {
        return loadStream(endpoint: streamKind.endpoint, streamKind: streamKind, success: success, failure: failure, noContent: noContent)
    }

    open func loadStream(
        endpoint: ElloAPI,
        streamKind: StreamKind?,
        success: @escaping StreamSuccessCompletion,
        failure: @escaping ElloFailureCompletion = { _ in },
        noContent: @escaping ElloEmptyCompletion = {})
    {
        ElloProvider.shared.elloRequest(
            endpoint,
            success: { (data, responseConfig) in
                if let jsonables = data as? [JSONAble] {
                    if let streamKind = streamKind {
                        Preloader().preloadImages(jsonables)
                        NewContentService().updateCreatedAt(jsonables, streamKind: streamKind)
                    }
                    success(jsonables, responseConfig)
                }
                else {
                    noContent()
                }

                // this must be the last thing, after success() or noContent() is called.
                if let streamKind = streamKind {
                    postNotification(StreamLoadedNotifications.streamLoaded, value: streamKind)
                }
            },
            failure: { (error, statusCode) in
                failure(error, statusCode)
            })
    }

    open func loadUser(
        _ endpoint: ElloAPI,
        streamKind: StreamKind?,
        success: @escaping UserSuccessCompletion,
        failure: @escaping ElloFailureCompletion)
    {
        ElloProvider.shared.elloRequest(
            endpoint,
            success: { (data, responseConfig) in
                if let user = data as? User {
                    Preloader().preloadImages([user])
                    success(user, responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }

    open func loadUserPosts(
        _ userId: String,
        success: @escaping UserPostsSuccessCompletion,
        failure: @escaping ElloFailureCompletion)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.userStreamPosts(userId: userId),
            success: { (data, responseConfig) in
                let posts: [Post]?
                if data as? String == "" {
                    posts = []
                }
                else if let foundPosts = data as? [Post] {
                    posts = foundPosts
                }
                else {
                    posts = nil
                }

                if let posts = posts {
                    Preloader().preloadImages(posts)
                    success(posts, responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }

    open func loadMoreCommentsForPost(
        _ postId: String,
        streamKind: StreamKind?,
        success: @escaping StreamSuccessCompletion,
        failure: @escaping ElloFailureCompletion,
        noContent: @escaping ElloEmptyCompletion = {})
    {
        ElloProvider.shared.elloRequest(
            .postComments(postId: postId),
            success: { (data, responseConfig) in
                if let comments: [ElloComment] = data as? [ElloComment] {
                    for comment in comments {
                        comment.loadedFromPostId = postId
                    }

                    Preloader().preloadImages(comments)
                    success(comments, responseConfig)
                }
                else if (data as? String) == "" {
                    noContent()
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure
        )
    }
}
