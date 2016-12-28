////
///  ContentFlaggingService.swift
//

import Moya
import SwiftyJSON

public typealias ContentFlaggingSuccessCompletion = () -> Void

public struct ContentFlaggingService {

    public init(){}

    public func flagContent(_ endpoint: ElloAPI, success: @escaping ContentFlaggingSuccessCompletion, failure: @escaping ElloFailureCompletion) {
        ElloProvider.shared.elloRequest(endpoint,
            success: { data in
                success()
        }, failure: failure)
    }
}
