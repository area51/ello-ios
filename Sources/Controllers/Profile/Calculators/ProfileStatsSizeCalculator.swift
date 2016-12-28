////
///  ProfileStatsSizeCalculator.swift
//

import FutureKit


public struct ProfileStatsSizeCalculator {

    public func calculate(_ item: StreamCellItem) -> Future<CGFloat> {
        let promise = Promise<CGFloat>()
        promise.completeWithSuccess(ProfileStatsView.Size.height)
        return promise.future
    }
}

private extension ProfileStatsSizeCalculator {}
