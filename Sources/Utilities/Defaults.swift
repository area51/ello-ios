////
///  Defaults.swift
//

import Foundation

public let ElloGroupName = "group.ello.Ello"
public let GroupDefaults = defaults()

private func defaults() -> UserDefaults {
    if AppSetup.sharedState.isTesting {
        return UserDefaults.standard
    }

    return UserDefaults(suiteName: ElloGroupName) ?? UserDefaults.standard
}
