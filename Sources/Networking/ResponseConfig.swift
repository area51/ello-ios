////
///  ResponseConfig.swift
//

import Foundation

open class ResponseConfig: CustomStringConvertible {
    open var description: String {
        let descripArray = [
            "ResponseConfig:",
            "nextQueryItems: \(nextQueryItems)",
            "prevQueryItems: \(prevQueryItems)",
            "firstQueryItems: \(firstQueryItems)",
            "lastQueryItems: \(lastQueryItems)",
            "totalPages: \(totalPages)",
            "totalCount: \(totalCount)",
            "totalPagesRemaining: \(totalPagesRemaining)"
        ]
        return descripArray.joined(separator: "\n\t")
    }
    open var nextQueryItems: [AnyObject]? // before (older)
    open var prevQueryItems: [AnyObject]? // after (newer)
    open var firstQueryItems: [AnyObject]? // first page
    open var lastQueryItems: [AnyObject]? // last page
    open var totalCount: String?
    open var totalPages: String?
    open var totalPagesRemaining: String?
    open var statusCode: Int?
    open var lastModified: String?
    open var isFinalValue: Bool

    public init(isFinalValue: Bool = true) {
        self.isFinalValue = isFinalValue
    }

    open func isOutOfData() -> Bool {

        return totalPagesRemaining == "0"
            || totalPagesRemaining == nil
            || nextQueryItems?.count == 0
            || nextQueryItems == nil
    }
}
