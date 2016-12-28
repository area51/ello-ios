////
///  BuyButtonLinkViewController.swift
//

public protocol BuyButtonLinkControllerDelegate: class {
    func submitBuyButtonLink(_ url: URL)
    func clearBuyButtonLink()
}

open class BuyButtonLinkViewController: UIViewController {
    var screen: BuyButtonLinkScreen { return self.view as! BuyButtonLinkScreen }
    var buyButtonURL: URL?
    weak var delegate: BuyButtonLinkControllerDelegate?

    required public init(buyButtonURL: URL?) {
        self.buyButtonURL = buyButtonURL
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        let screen = BuyButtonLinkScreen()
        screen.buyButtonURL = buyButtonURL
        screen.delegate = self
        view = screen
    }

}

extension BuyButtonLinkViewController: BuyButtonLinkDelegate {

    public func closeModal() {
        dismiss(animated: true, completion: nil)
    }

    public func submitLink(_ url: URL) {
        delegate?.submitBuyButtonLink(url)
    }

    public func clearLink() {
        delegate?.clearBuyButtonLink()
    }

}
