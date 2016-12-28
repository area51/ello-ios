////
///  Onboarding.swift
//

import SwiftyUserDefaults


private let _sharedInstance = Onboarding()
private let _currentVersion = 2

open class Onboarding {
    open static var currentVersion: Int {
        return _currentVersion
    }

    open func updateVersionToLatest() {
        ProfileService().updateUserProfile(["web_onboarding_version": _currentVersion as AnyObject], success: { _ in }, failure: { _ in })
    }

    open class func shared() -> Onboarding {
        return _sharedInstance
    }

    init() {
    }

    // only show if webVersion is nil
    open func showOnboarding(_ user: User) -> Bool {
        return user.onboardingVersion == nil
    }

}
