////
///  StreamTextCell.swift
//

import WebKit
import Foundation

open class StreamTextCell: StreamRegionableCell, UIWebViewDelegate, UIGestureRecognizerDelegate {
    static let reuseIdentifier = "StreamTextCell"

    typealias WebContentReady = (_ webView: UIWebView) -> Void

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    weak var webLinkDelegate: WebLinkDelegate?
    weak var userDelegate: UserDelegate?
    weak var streamEditingDelegate: StreamEditingDelegate?
    var webContentReady: WebContentReady?

    override open func awakeFromNib() {
        super.awakeFromNib()
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.scrollsToTop = false

        let doubleTapGesture = UITapGestureRecognizer()
        doubleTapGesture.delegate = self
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.addTarget(self, action: #selector(doubleTapped(_:)))
        webView.addGestureRecognizer(doubleTapGesture)

        let longPressGesture = UILongPressGestureRecognizer()
        longPressGesture.addTarget(self, action: #selector(longPressed(_:)))
        webView.addGestureRecognizer(longPressGesture)
    }

    open func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }

    @IBAction func doubleTapped(_ gesture: UIGestureRecognizer) {
        let location = gesture.location(in: nil)
        streamEditingDelegate?.cellDoubleTapped(cell: self, location: location)
    }

    @IBAction func longPressed(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            streamEditingDelegate?.cellLongPressed(cell: self)
        }
    }

    func onWebContentReady(_ handler: WebContentReady?) {
        webContentReady = handler
    }

    override open func prepareForReuse() {
        super.prepareForReuse()
        hideBorder()
        webContentReady = nil
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }

    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let scheme = request.url?.scheme, scheme == "default"
        {
            userDelegate?.userTappedText(cell: self)
            return false
        }
        else {
            return ElloWebViewHelper.handle(request: request, webLinkDelegate: webLinkDelegate)
        }
    }

    open func webViewDidFinishLoad(_ webView: UIWebView) {
        webContentReady?(webView)
    }
}
