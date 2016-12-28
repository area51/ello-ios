////
///  ShareTrackerOverrides.swift
//

import Foundation

public enum ContentType: String {
    case post = "Post"
    case comment = "Comment"
    case user = "User"
}

func logPresentingAlert(_ name: String) {}

open class Tracker {
    open static let sharedTracker = Tracker()

    public init() {}

    static func trackRequest(headers: String, statusCode: Int, responseJSON: String) {}

    func contentFlagged(_ type: ContentType, flag: ContentFlagger.AlertOption, contentId: String) {}
    func contentFlaggingFailed(_ type: ContentType, message: String, contentId: String) {}
    func contentFlaggingCanceled(_ type: ContentType, contentId: String) {}
    func createdAtCrash(_ identifier: String, json: String?) {}
    func encounteredNetworkError(_ path: String, error: NSError, statusCode: Int?) {}
}

open class Window {
    static open func isWide(_ width: Float) -> Bool { return false }
    static open var width: Float { return 0 }
}
