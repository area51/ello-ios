////
///  ProfileHeaderLayoutView.swift
//

import SnapKit
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



open class ProfileHeaderLayoutView: ProfileBaseView {
    var calculatedCellHeights: CalculatedCellHeights? {
        didSet {
            guard let calculatedCellHeights = calculatedCellHeights else { return }

            if let avatarHeight = calculatedCellHeights.profileAvatar { avatarHeightConstraint.update(offset: avatarHeight) }
            if let namesHeight = calculatedCellHeights.profileNames { namesHeightConstraint.update(offset: namesHeight) }
            if let totalCountHeight = calculatedCellHeights.profileTotalCount { totalCountHeightConstraint.update(offset: totalCountHeight) }
            if let bioHeight = calculatedCellHeights.profileBio { bioHeightConstraint.update(offset: bioHeight) }
            if let locationHeight = calculatedCellHeights.profileLocation { locationHeightConstraint.update(offset: locationHeight) }
            if let linksHeight = calculatedCellHeights.profileLinks { linksHeightConstraint.update(offset: linksHeight) }

            let bioLinksOrLocationHaveContent = calculatedCellHeights.profileBio > 0 || calculatedCellHeights.profileLinks > 0 || calculatedCellHeights.profileLocation > 0
            statsView.grayLineVisible = bioLinksOrLocationHaveContent

            let locationOrLinksHasContent = calculatedCellHeights.profileLocation > 0 || calculatedCellHeights.profileLinks > 0
            bioView.grayLineVisible = locationOrLinksHasContent

            let linksHasContent = calculatedCellHeights.profileLinks > 0
            locationView.grayLineVisible = linksHasContent

            setNeedsLayout()
        }
    }

    let avatarView = ProfileAvatarView()
    let namesView = ProfileNamesView()
    let totalCountView = ProfileTotalCountView()
    let statsView = ProfileStatsView()
    let bioView = ProfileBioView()
    let locationView = ProfileLocationView()
    let linksView = ProfileLinksView()

    var avatarHeightConstraint: Constraint!
    var namesHeightConstraint: Constraint!
    var totalCountHeightConstraint: Constraint!
    var bioHeightConstraint: Constraint!
    var locationHeightConstraint: Constraint!
    var linksHeightConstraint: Constraint!
}
