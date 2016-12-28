////
///  BaseElloViewController.swift
//

@objc public protocol ControllerThatMightHaveTheCurrentUser {
    var currentUser: User? { get set }
}

open class BaseElloViewController: UIViewController, ControllerThatMightHaveTheCurrentUser {

    open var elloNavigationItem = UINavigationItem()

    override open var title: String? {
        didSet {
            elloNavigationItem.title = title ?? ""
        }
    }

    open var currentUser: User? {
        didSet { didSetCurrentUser() }
    }

    var appViewController: AppViewController? {
        return findViewController { vc in vc is AppViewController } as? AppViewController
    }

    var elloTabBarController: ElloTabBarController? {
        return findViewController { vc in vc is ElloTabBarController } as? ElloTabBarController
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.fixNavBarItemPadding()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
    }

    func didSetCurrentUser() {}

    @IBAction
    func backTapped() {
        guard
            let navigationController = navigationController, navigationController.childViewControllers.count > 1 else { return }

        _ = navigationController.popViewController(animated: true)
    }

    open func isRootViewController() -> Bool {
        if let viewControllers = navigationController?.viewControllers {
            return (viewControllers[0] ) == self
        }
        return false
    }
}

// MARK: Search
public extension BaseElloViewController {
    func searchButtonTapped() {
        let search = SearchViewController()
        search.currentUser = currentUser
        self.navigationController?.pushViewController(search, animated: true)
    }
}
