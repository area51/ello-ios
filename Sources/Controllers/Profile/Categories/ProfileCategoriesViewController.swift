////
///  ProfileCategoriesViewController.swift
//

public final class ProfileCategoriesViewController: BaseElloViewController {

    var categories = [Category]()
    public init(categories: [Category]) {
        super.init(nibName: nil, bundle: nil)
        self.categories = categories
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var mockScreen: ProfileCategoriesProtocol?
    var screen: ProfileCategoriesProtocol { return mockScreen ?? (self.view as! ProfileCategoriesProtocol) }

    override public func loadView() {
        let screen = ProfileCategoriesScreen(categories: categories)
        screen.delegate = self
        self.view = screen
    }
}

// MARK: UIViewControllerTransitioningDelegate
extension ProfileCategoriesViewController: UIViewControllerTransitioningDelegate {

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard presented == self
            else { return .none }

        return ProfileCategoriesPresentationController(presentedViewController: presented, presentingViewController: presenting, backgroundColor: .modalBackground())
    }
}

extension ProfileCategoriesViewController: ProfileCategoriesDelegate {

    public func categoryTapped(_ category: Category) {
		Tracker.sharedTracker.categoryOpened(category.slug)
        let vc = CategoryViewController(slug: category.slug, name: category.name)
        vc.currentUser = currentUser

        navigationController?.pushViewController(vc, animated: true)
    }

    public func dismiss() {
        self.dismiss(animated: true, completion: .none)
    }
}
