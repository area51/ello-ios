////
///  InviteFriendsViewController.swift
//

open class InviteFriendsViewController: StreamableViewController {
    let addressBook: AddressBookProtocol
    var mockScreen: Screen?
    var screen: Screen { return mockScreen ?? (self.view as! Screen) }
    var parentAppController: AppViewController?
    var searchString = SearchString(text: "")
    open var onboardingViewController: OnboardingViewController?
    open var onboardingData: OnboardingData!

    required public init(addressBook: AddressBookProtocol) {
        self.addressBook = addressBook
        super.init(nibName: nil, bundle: nil)

        streamViewController.initialLoadClosure = { [unowned self] in self.findFriendsFromContacts() }
        streamViewController.pullToRefreshEnabled = false
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

        streamViewController.searchStreamDelegate = self
        scrollLogic.prevOffset = streamViewController.collectionView.contentOffset
        streamViewController.loadInitialPage()
    }

    override open func showNavBars(_ scrollToBottom: Bool) {}
    override open func hideNavBars() {}
}

extension InviteFriendsViewController {
    fileprivate func findFriendsFromContacts() {
        ElloHUD.showLoadingHudInView(view)
        InviteService().find(addressBook,
            currentUser: self.currentUser,
            success: { mixedContacts in
                self.streamViewController.clearForInitialLoad()
                self.setContacts(mixedContacts)
                self.streamViewController.doneLoading()
            },
            failure: { _ in
                let mixedContacts: [(LocalPerson, User?)] = self.addressBook.localPeople.map { ($0, .none) }
                self.setContacts(mixedContacts)
                self.streamViewController.doneLoading()
            })
    }

    fileprivate func setContacts(_ contacts: [(LocalPerson, User?)]) {
        ElloHUD.hideLoadingHudInView(view)

        let header = NSAttributedString(
            primaryHeader: InterfaceString.Onboard.InviteFriendsPrimary,
            secondaryHeader: InterfaceString.Onboard.InviteFriendsSecondary
            )
        let headerCellItem = StreamCellItem(type: .textHeader(header))
        let searchItem = StreamCellItem(jsonable: searchString, type: .search(placeholder: InterfaceString.Onboard.Search))

        let addressBookItems: [StreamCellItem] = AddressBookHelpers.process(contacts, currentUser: currentUser).map { item in
            if item.type == .inviteFriends {
                item.type = .onboardingInviteFriends
            }
            return item
        }
        let items = [headerCellItem, searchItem] + addressBookItems
        streamViewController.appendStreamCellItems(items)
    }
}

extension InviteFriendsViewController: OnboardingStepController {
    public func onboardingStepBegin() {
        onboardingViewController?.hasAbortButton = false
        onboardingViewController?.canGoNext = true
    }

    public func onboardingWillProceed(abort: Bool, proceedClosure: @escaping (_ success: OnboardingViewController.OnboardingProceed) -> Void) {
        proceedClosure(.continue)
    }
}

extension InviteFriendsViewController: SearchStreamDelegate {
    public func searchFieldChanged(text: String) {
        searchString.text = text
        streamViewController.batchUpdateFilter(AddressBookHelpers.searchFilter(text))
    }
}
