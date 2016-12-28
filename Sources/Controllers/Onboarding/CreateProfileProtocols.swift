////
///  CreateProfileProtocols.swift
//

protocol CreateProfileDelegate: class {
    func presentController(_ controller: UIViewController)
    func dismissController()

    func assignName(_ name: String?) -> ValidationState
    func assignBio(_ bio: String?) -> ValidationState
    func assignLinks(_ links: String?) -> ValidationState
    func assignCoverImage(_ image: ImageRegionData)
    func assignAvatar(_ image: ImageRegionData)
}

protocol CreateProfileScreenProtocol: class {
    var name: String? { get set }
    var bio: String? { get set }
    var links: String? { get set }
    var linksValid: Bool? { get set }
    var coverImage: ImageRegionData? { get set }
    var avatarImage: ImageRegionData? { get set }
}
