////
///  ElloNavigationController.swift
//

public let ExternalWebNotification = TypedNotification<String>(name: "ExternalWebNotification")

open class ElloNavigationController: UINavigationController, ControllerThatMightHaveTheCurrentUser {

    var interactionController: UIPercentDrivenInteractiveTransition?
    var postChangedNotification: NotificationObserver?
    var relationshipChangedNotification: NotificationObserver?
    var rootViewControllerName: String?
    open var currentUser: User? {
        didSet { didSetCurrentUser() }
    }

    var backGesture: UIScreenEdgePanGestureRecognizer?

    override open var tabBarItem: UITabBarItem? {
        get { return childViewControllers.first?.tabBarItem ?? super.tabBarItem }
        set { self.tabBarItem = newValue }
    }

    enum RootViewControllers: String {
        case notifications = "NotificationsViewController"
        case profile = "ProfileViewController"
        case omnibar = "OmnibarViewController"
        case discover = "DiscoverAllCategoriesViewController"

        func controllerInstance(_ user: User) -> BaseElloViewController {
            switch self {
            case .notifications: return NotificationsViewController()
            case .profile: return ProfileViewController(user: user)
            case .omnibar:
                let vc = OmnibarViewController()
                vc.canGoBack = false
                return vc
            case .discover: return DiscoverAllCategoriesViewController()
            }
        }
    }

    func didSetCurrentUser() {
        if self.viewControllers.count == 0 {
            if let
                rootViewControllerName = rootViewControllerName,
                let currentUser = currentUser
            {
                if let controller = RootViewControllers(rawValue:rootViewControllerName)?.controllerInstance(currentUser) {
                    controller.currentUser = currentUser
                    self.viewControllers = [controller]
                }
            }
        }
        else {
            for controller in self.viewControllers {
                if let controller = controller as? ControllerThatMightHaveTheCurrentUser {
                    controller.currentUser = currentUser
                }
            }
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationBarHidden(true, animated: false)

        delegate = self

        backGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ElloNavigationController.handleBackGesture(_:)))
        if let backGesture = backGesture {
            self.view.addGestureRecognizer(backGesture)
        }

        postChangedNotification = NotificationObserver(notification: PostChangedNotification) { (post, change) in
            switch change {
            case .delete:
                var keepers = [UIViewController]()
                for controller in self.childViewControllers {
                    if let postDetailVC = controller as? PostDetailViewController {
                        if let postId = postDetailVC.post?.id, postId != post.id {
                            keepers.append(controller)
                        }
                    }
                    else {
                        keepers.append(controller)
                    }
                }
                self.setViewControllers(keepers, animated: true)
            default: break
            }
        }

        relationshipChangedNotification = NotificationObserver(notification: RelationshipChangedNotification) { user in
            switch user.relationshipPriority {
            case .block:
                var keepers = [UIViewController]()
                for controller in self.childViewControllers {
                    if let userStreamVC = controller as? ProfileViewController {
                        if let userId = userStreamVC.user?.id, userId != user.id {
                            keepers.append(controller)
                        }
                    }
                    else {
                        keepers.append(controller)
                    }
                }
                self.setViewControllers(keepers, animated: true)
            default:
                break
            }
        }
    }

    func handleBackGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let percentThroughView = gesture.percentageThroughView(gesture.edges)

        switch gesture.state {
        case .began:
            interactionController = UIPercentDrivenInteractiveTransition()
            topViewController?.backGestureAction()
        case .changed:
            interactionController?.update(percentThroughView)
        case .ended, .cancelled:
            if percentThroughView > 0.5 {
                interactionController?.finish()
            } else {
                interactionController?.cancel()
            }
            interactionController = nil
        default:
            interactionController = nil
        }
    }

}

extension ElloNavigationController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

private let throttledTracker = debounce(0.1)
extension ElloNavigationController: UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        backGesture?.edges = viewController.backGestureEdges

        throttledTracker {
            Tracker.sharedTracker.screenAppeared(viewController)
        }
    }

    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        switch operation {
        case .push: return ForwardAnimator()
        case .pop: return BackAnimator()
        default: return .none
        }
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

}
