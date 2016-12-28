////
///  Date.swift
//

import Foundation

public extension Date {

    public func toServerDateString() -> String {
        return ServerDateFormatter.string(from: self)
    }

    public func toHTTPDateString() -> String {
        return HTTPDateFormatter.string(from: self)
    }

    public var isInPast: Bool {
        let now = Date()
        return self.compare(now) == ComparisonResult.orderedAscending
    }

}
