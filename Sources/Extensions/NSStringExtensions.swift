////
///  NSStringExtensions.swift
//

import Foundation

public extension NSString {
    func toDate(_ formatter: DateFormatter = ServerDateFormatter) -> Date? {
        return formatter.date(from: self as String)
    }
}
