////
///  AvailabilityService.swift
//

import Moya
import SwiftyJSON

public typealias AvailabilitySuccessCompletion = (Availability) -> Void

public struct AvailabilityService {

    public init(){}

    func usernameAvailability(_ username: String, success: @escaping AvailabilitySuccessCompletion, failure: @escaping ElloFailureCompletion) {
        availability(["username": username], success: success, failure: failure)
    }

    func emailAvailability(_ email: String, success: @escaping AvailabilitySuccessCompletion, failure: @escaping ElloFailureCompletion) {
        availability(["email": email], success: success, failure: failure)
    }

    public func availability(_ content: [String: String], success: @escaping AvailabilitySuccessCompletion, failure: @escaping ElloFailureCompletion) {
        let endpoint = ElloAPI.availability(content: content)
        ElloProvider.shared.elloRequest(endpoint,
            success: { data, _ in
                if let data = data as? Availability {
                    success(data)
                } else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: failure)
    }
}
