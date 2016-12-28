////
///  LoadingToken.swift
//

import Foundation

public struct LoadingToken {
    fileprivate var loadInitialPageLoadingToken: String = ""
    public var cancelLoadingClosure: ElloEmptyCompletion = {}

    public mutating func resetInitialPageLoadingToken() -> String {
        let newToken = UUID().uuidString
        loadInitialPageLoadingToken = newToken
        return newToken
    }

    public func isValidInitialPageLoadingToken(_ token: String) -> Bool {
        return loadInitialPageLoadingToken == token
    }

    public mutating func cancelInitialPage() {
        _ = resetInitialPageLoadingToken()
        self.cancelLoadingClosure()
    }
}
