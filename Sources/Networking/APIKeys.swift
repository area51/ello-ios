////
///  APIKeys.swift
//

import Foundation
import Keys

// Mark: - API Keys

public struct APIKeys {
    let key: String
    let secret: String

    // MARK: Shared Keys

    fileprivate struct SharedKeys {
        static var instance = APIKeys()
    }

    public static var sharedKeys: APIKeys {
        get {
        return SharedKeys.instance
        }

        set (newSharedKeys) {
            SharedKeys.instance = newSharedKeys
        }
    }

    // MARK: Methods

    public var stubResponses: Bool {
        return key.characters.count == 0 || secret.characters.count == 0
    }

    // MARK: Initializers

    public init(key: String, secret: String) {
        self.key = key
        self.secret = secret
    }

    public init() {
        let key: String = ElloKeys().oauthKey()
        let secret: String = ElloKeys().oauthSecret()
        self.init(key: key, secret: secret)
    }
}
