////
///  ProfileBioPresenter.swift
//

import Foundation


public struct ProfileBioPresenter {

    public static func configure(
        _ view: ProfileBioView,
        user: User,
        currentUser: User?)
    {
        view.bio = user.formattedShortBio ?? ""
    }
}
