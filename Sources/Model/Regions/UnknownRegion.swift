////
///  UnknownRegion.swift
//

import Foundation

let UnknownRegionVersion = 1

@objc(UnknownRegion)
public final class UnknownRegion: NSObject, Regionable, NSCoding {
    public let version = UnknownRegionVersion
    public var isRepost: Bool = false

    public var kind: String { return RegionKind.unknown.rawValue }

    public func coding() -> NSCoding {
        return self
    }

    // no-op initializer to allow stubbing
    public init(name: String) {}


// MARK: NSCoding

    public func encode(with encoder: NSCoder) {
    }

    required public init?(coder decoder: NSCoder) {

    }

    public func toJSON() -> [String: AnyObject] {
        return [:]
    }
}
