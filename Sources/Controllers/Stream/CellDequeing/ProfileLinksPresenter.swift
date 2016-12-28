////
///  ProfileLinksPresenter.swift
//

import Foundation


public struct ProfileLinksPresenter {

    public static func configure(
        _ view: ProfileLinksView,
        user: User,
        currentUser: User?)
    {
        guard let links = user.externalLinksList else { return }

        view.externalLinks = links
    }
}
