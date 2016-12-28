////
///  ProfileAvatarPresenter.swift
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



public struct ProfileAvatarPresenter {

    public static func configure(
        _ view: ProfileAvatarView,
        user: User,
        currentUser: User?)
    {
        let isCurrentUser = (user.id == currentUser?.id)
        if let cachedImage = TemporaryCache.load(.avatar), isCurrentUser
        {
            view.avatarImage = cachedImage
        }
        else if let url = user.avatarURL(viewsAdultContent: currentUser?.viewsAdultContent, animated: true) {
            view.avatarURL = url
        }

        view.badgeVisible = user.totalViewsCount == nil && user.categories?.count > 0
    }
}
