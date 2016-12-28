////
///  CategoriesSelectionViewController.swift
//

open class CategoriesSelectionViewController: StreamableViewController, HasAppController {
    var mockScreen: Screen?
    var screen: Screen { return mockScreen ?? (self.view as! Screen) }
    var parentAppController: AppViewController?
    var selectedCategories: [Category] = []
    open var onboardingViewController: OnboardingViewController?
    open var onboardingData: OnboardingData!

    required public init() {
        super.init(nibName: nil, bundle: nil)
        streamViewController.streamKind = .allCategories
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        let screen = Screen()
        self.view = screen
        viewContainer = screen
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        streamViewController.selectedCategoryDelegate = self
        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()
    }

    override open func showNavBars(_ scrollToBottom: Bool) {}
    override open func hideNavBars() {}

    override open func streamViewStreamCellItems(jsonables: [JSONAble], defaultGenerator generator: StreamCellItemGenerator) -> [StreamCellItem]? {
        let header = NSAttributedString(
            primaryHeader: InterfaceString.Onboard.PickCategoriesPrimary,
            secondaryHeader: InterfaceString.Onboard.PickCategoriesSecondary
            )
        let headerCellItem = StreamCellItem(type: .textHeader(header))
        var items: [StreamCellItem] = [headerCellItem]

        if let categories = jsonables as? [Category] {
            let onboardingCategories = categories.filter { $0.allowInOnboarding }
            items += onboardingCategories.map { StreamCellItem(jsonable: $0, type: .selectableCategoryCard) }
        }
        return items
    }
}

extension CategoriesSelectionViewController: OnboardingStepController {
    public func onboardingStepBegin() {
        let prompt = NSString(format: InterfaceString.Onboard.PickTemplate as NSString, 3) as String
        onboardingViewController?.hasAbortButton = false
        onboardingViewController?.canGoNext = false
        onboardingViewController?.prompt = prompt
    }

    public func onboardingWillProceed(abort: Bool, proceedClosure: @escaping (_ success: OnboardingViewController.OnboardingProceed) -> Void) {
        if selectedCategories.count > 0 {
            let categories = self.selectedCategories
            for category in categories {
                Tracker.sharedTracker.onboardingCategorySelected(category)
            }

            UserService().setUser(categories: categories)
                .onSuccess { _ in
                    // onboarding can be considered "done", even if they abort the app
                    Onboarding.shared().updateVersionToLatest()

                    self.onboardingData.categories = categories
                    proceedClosure(.continue)
                }
                .onFail { _ in
                    let alertController = AlertViewController(error: InterfaceString.GenericError)
                    self.parentAppController?.present(alertController, animated: true, completion: nil)
                    proceedClosure(.error)
                }
        }
    }
}

extension CategoriesSelectionViewController: SelectedCategoryDelegate {
    public func categoriesSelectionChanged(selection: [Category]) {
        let selectionCount = selection.count
        let prompt: String?
        let canGoNext: Bool
        switch selectionCount {
        case 0, 1, 2:
            prompt = NSString(format: InterfaceString.Onboard.PickTemplate as NSString, 3 - selectionCount) as String
            canGoNext = false
        default:
            prompt = nil
            canGoNext = true
        }

        selectedCategories = selection
        onboardingViewController?.prompt = prompt
        onboardingViewController?.canGoNext = canGoNext
    }
}
