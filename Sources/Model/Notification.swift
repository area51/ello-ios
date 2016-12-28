////
///  Notification.swift
//

import Foundation

public enum NotificationFilterType: String {
    case all = "NotificationFilterTypeAll"
    case comments = "NotificationFilterTypeComments"
    case mention = "NotificationFilterTypeMention"
    case heart = "NotificationFilterTypeHeart"
    case repost = "NotificationFilterTypeRepost"
    case relationship = "NotificationFilterTypeRelationship"

    var category: String? {
        switch self {
            case .all:
                return nil
            case .comments:  // …
                return "comments"
            case .mention:  // @
                return "mentions"
            case .heart:
                return "loves"
            case .repost:
                return "reposts"
            case .relationship:
                return "relationships"
        }
    }

    static func fromCategory(_ categoryString: String?) -> NotificationFilterType {
        let category = categoryString ?? ""
        switch category {
        case "comments": return .comments
        case "mentions": return .mention
        case "loves": return .heart
        case "reposts": return .repost
        case "relationships": return .relationship
        default: return .all
        }
    }
}

let NotificationVersion = 1

@objc(Notification)
public final class Notification: JSONAble, Authorable, Groupable {

    // required
    public let activity: Activity
    // optional
    public var author: User?
    // if postId is present, this notification is opened using "PostDetailViewController"
    public var postId: String?
    // computed
    public var createdAt: Date { return activity.createdAt as Date }
    public var groupId: String { return "Notification-\(activity.id)" }
    public var subject: JSONAble? { willSet { attributedTitleStore = nil } }

    // notification specific
    public var textRegion: TextRegion?
    public var imageRegion: ImageRegion?
    fileprivate var attributedTitleStore: NSAttributedString? = nil
    public var attributedTitle: NSAttributedString {
        if let attributedTitle = attributedTitleStore {
            return attributedTitle
        }
        attributedTitleStore = NotificationAttributedTitle.attributedTitle(activity.kind, author: author, subject: subject)
        return attributedTitleStore!
    }

    public var hasImage: Bool {
        return self.imageRegion != nil
    }
    public var canReplyToComment: Bool {
        switch activity.kind {
        case .postMentionNotification,
            .commentNotification,
            .commentMentionNotification,
            .commentOnOriginalPostNotification,
            .commentOnRepostNotification:
            return true
        default:
            return false
        }
    }
    public var canBackFollow: Bool {
        return false // activity.kind == .newFollowerPost
    }

    public var isValidKind: Bool {
        return activity.kind != .unknown
    }

// MARK: Initialization

    public init(activity: Activity) {
        self.activity = activity

        if let post = activity.subject as? Post {
            self.author = post.author
            self.postId = post.id
        }
        else if let comment = activity.subject as? ElloComment {
            self.author = comment.author
            self.postId = comment.postId
        }
        else if let user = activity.subject as? User {
            self.author = user
        }
        else if let actionable = activity.subject as? PostActionable,
            let user = actionable.user
        {
            self.postId = actionable.postId
            self.author = user
        }

        super.init(version: NotificationVersion)

        if let post = activity.subject as? Post {
            assignRegionsFromContent(post.summary)
        }
        else if let comment = activity.subject as? ElloComment {
            let parentSummary = comment.parentPost?.summary
            if let summary = comment.summary {
                assignRegionsFromContent(summary, parentSummary: parentSummary)
            }
            else {
                assignRegionsFromContent(comment.content, parentSummary: parentSummary)
            }
        }
        else if let post = (activity.subject as? Love)?.post {
            assignRegionsFromContent(post.summary)
        }

        subject = activity.subject
    }

// MARK: NSCoding

    public required init(coder aDecoder: NSCoder) {
        let decoder = Coder(aDecoder)
        self.activity = decoder.decodeKey("activity")
        self.author = decoder.decodeOptionalKey("author")
        super.init(coder: decoder.coder)
    }

    public override func encode(with encoder: NSCoder) {
        let coder = Coder(encoder)
        coder.encodeObject(activity, forKey: "activity")
        coder.encodeObject(author, forKey: "author")
        super.encode(with: coder.coder)
    }

// MARK: Private

    fileprivate func assignRegionsFromContent(_ content: [Regionable], parentSummary: [Regionable]? = nil) {
        // assign textRegion and imageRegion from the post content - finds
        // the first of both kinds of regions
        var textContent: [String] = []
        var parentImage: ImageRegion?
        var contentImage: ImageRegion?

        if let parentSummary = parentSummary {
            for region in parentSummary {
                if let newTextRegion = region as? TextRegion {
                    textContent.append(newTextRegion.content)
                }
                else if let newImageRegion = region as? ImageRegion, parentImage == nil
                {
                    parentImage = newImageRegion
                }
            }
        }

        for region in content {
            if let newTextRegion = region as? TextRegion {
                textContent.append(newTextRegion.content)
            }
            else if let newImageRegion = region as? ImageRegion, contentImage == nil
            {
                contentImage = newImageRegion
            }
        }

        imageRegion = contentImage ?? parentImage
        textRegion = TextRegion(content: textContent.joined(separator: "<br/>"))
    }
}

extension Notification: JSONSaveable {
    var uniqueId: String? { if let id = tableId { return "Notification-\(id)" } ; return nil }
    var tableId: String? { return activity.id }

}
