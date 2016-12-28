////
///  OmnibarScreenBuyButtonLinkControllerDelegate.swift
//

extension OmnibarScreen: BuyButtonLinkControllerDelegate {

    public func submitBuyButtonLink(_ url: URL) {
        buyButtonURL = url
        regionsTableView.reloadData()
    }

    public func clearBuyButtonLink() {
        buyButtonURL = nil
        regionsTableView.reloadData()
    }

}
