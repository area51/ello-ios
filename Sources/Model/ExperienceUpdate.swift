////
///  ExperienceUpdate.swift
//

public let CommentChangedNotification = TypedNotification<(ElloComment, ContentChange)>(name: "commentChangedNotification")
public let PostChangedNotification = TypedNotification<(Post, ContentChange)>(name: "postChangedNotification")
public let PostCommentsCountChangedNotification = TypedNotification<(Post, Int)>(name: "postCommentsCountChangedNotification")
public let JSONAbleChangedNotification = TypedNotification<(JSONAble, ContentChange)>(name: "jsonableChangedNotification")
public let RelationshipChangedNotification = TypedNotification<User>(name: "relationshipChangedNotification")
public let BlockedCountChangedNotification = TypedNotification<(String, Int)>(name: "BlockedCountChangedNotification")
public let MutedCountChangedNotification = TypedNotification<(String, Int)>(name: "MutedCountChangedNotification")
public let CurrentUserChangedNotification = TypedNotification<User>(name: "currentUserChangedNotification")
public let SettingChangedNotification = TypedNotification<User>(name: "settingChangedNotification")

public enum ContentChange {
    case create
    case read
    case update
    case loved
    case watching
    case replaced
    case delete

    public static func updateCommentCount(_ comment: ElloComment, delta: Int) {
        var affectedPosts: [Post?]
        if comment.postId == comment.loadedFromPostId {
            affectedPosts = [comment.parentPost]
        }
        else {
            affectedPosts = [comment.parentPost, comment.loadedFromPost]
        }
        for post in affectedPosts {
            if let post = post, let count = post.commentsCount {
                postNotification(PostCommentsCountChangedNotification, value: (post, delta))
                postNotification(PostChangedNotification, value: (post, .update))

                // this must happen AFTER the notification, otherwise the
                // storedPost will be in-memory, and the notification will update the comment count
                if let storedPost = ElloLinkedStore.sharedInstance.getObject(post.id, type: .postsType) as? Post {
                    storedPost.commentsCount = count + delta
                    ElloLinkedStore.sharedInstance.setObject(storedPost, forKey: post.id, type: .postsType)
                }
            }
        }

    }

}
