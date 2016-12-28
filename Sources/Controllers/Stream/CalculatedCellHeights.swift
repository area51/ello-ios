////
///  CalculatedCellHeights.swift
//


public typealias OnCalculatedCellHeightsMismatch = (CalculatedCellHeights) -> Void

public struct CalculatedCellHeights {
    public enum Prop {
        case oneColumn
        case multiColumn
        case webContent
        case profileAvatar
        case profileNames
        case profileTotalCount
        case profileStats
        case profileBio
        case profileLocation
        case profileLinks
    }

    mutating func assign(_ prop: Prop, height: CGFloat) {
        switch prop {
        case .profileAvatar:
            profileAvatar = height
        case .profileNames:
            profileNames = height
        case .profileTotalCount:
            profileTotalCount = height
        case .profileStats:
            profileStats = height
        case .profileBio:
            profileBio = height
        case .profileLocation:
            profileLocation = height
        case .profileLinks:
            profileLinks = height
        default: break
        }
    }

    public var oneColumn: CGFloat?
    public var multiColumn: CGFloat?
    public var webContent: CGFloat?
    public var profileAvatar: CGFloat?
    public var profileNames: CGFloat?
    public var profileTotalCount: CGFloat?
    public var profileStats: CGFloat?
    public var profileBio: CGFloat?
    public var profileLocation: CGFloat?
    public var profileLinks: CGFloat?
}
