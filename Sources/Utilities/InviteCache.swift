////
///  InviteCache.swift
//

import Foundation

private let key = "ElloInviteCache"

public struct InviteCache {
    var cache: [String]

    public init() {
        if let existing = GroupDefaults[key].array as? [String] {
            cache = existing
        }
        else {
            cache = []
        }
    }

    public mutating func saveInvite(_ contactID: String) {
        guard !has(contactID) else { return }

        cache.append(contactID)
        GroupDefaults[key] = cache
    }

    public func has(_ contactID: String) -> Bool {
        return cache.contains(contactID)
    }

    public mutating func clear() {
        cache = []
        GroupDefaults[key] = nil
    }
}
