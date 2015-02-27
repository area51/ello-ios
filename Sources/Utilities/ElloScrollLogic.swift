//
//  ElloScrollLogic.swift
//  Ello
//
//  Created by Colin Gray on 2/24/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

class ElloScrollLogic : NSObject, UIScrollViewDelegate {
    var prevOffset : CGPoint?
    var shouldIgnoreScroll:Bool = false
    private var showingState:Bool?
    var navBarHeight:CGFloat = 44
    var tabBarHeight:CGFloat = 49
    var barHeights:CGFloat { return navBarHeight + tabBarHeight }

    var isShowing : Bool {
        get { return self.showingState ?? true }
        set { showingState = newValue }
    }

    private var onShow: ((Bool)->())!
    private var onHide: (()->())!

    init(onShow: (Bool)->(), onHide: ()->()) {
        self.onShow = onShow
        self.onHide = onHide
    }

    func onShow(handler: (Bool)->()) {
        self.onShow = handler
    }

    func onHide(handler: ()->()) {
        self.onHide = handler
    }

    private func show(scrollToBottom : Bool = false) {
        if self.showingState == nil {
            println("setting showingState to false")
        }
        let wasShowing = self.showingState ?? false

        if !wasShowing {
            let prevIgnore = self.shouldIgnoreScroll
            self.shouldIgnoreScroll = true
            UIView.animateWithDuration(0.2, animations: {
                self.onShow(scrollToBottom)
                self.shouldIgnoreScroll = prevIgnore
            })
        }
        showingState = true
    }

    private func hide() {
        let wasShowing = self.showingState ?? true

        if wasShowing {
            let prevIgnore = self.shouldIgnoreScroll
            self.shouldIgnoreScroll = true
            UIView.animateWithDuration(0.2, animations: {
                self.onHide()
                self.shouldIgnoreScroll = prevIgnore
            })
        }
        showingState = false
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        var nextOffset = scrollView.contentOffset
        let shouldAcceptScroll = self.shouldAcceptScroll(scrollView)

        if shouldAcceptScroll {
            if let prevOffset = prevOffset {
                let didScrollDown = self.didScrollDown(scrollView.contentOffset, prevOffset)

                if didScrollDown {
                    hide()
                }
                else {
                    let isAtTop = self.isAtTop(scrollView)
                    let movedALittle = self.movedALittle(scrollView.contentOffset, prevOffset)
                    let movedALot = self.movedALot(scrollView.contentOffset, prevOffset)

                    if isAtTop || !movedALittle && !movedALot {
                        show()
                    }
                }
            }
        }

        prevOffset = nextOffset
    }

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        shouldIgnoreScroll = false
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate: Bool) {
        if self.isAtBottom(scrollView) {
            show(scrollToBottom: true)
        }
        else if self.isAtTop(scrollView) {
            show(scrollToBottom: false)
        }
        shouldIgnoreScroll = true
    }

    private func shouldAcceptScroll(scrollView : UIScrollView) -> Bool {
        let nearBottom = self.nearBottom(scrollView)
        if shouldIgnoreScroll || nearBottom {
            return false
        }

        let contentSizeHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height
        let buffer = CGFloat(10)
        return scrollViewHeight + barHeights + buffer < contentSizeHeight
    }

    private func nearBottom(scrollView : UIScrollView) -> Bool {
        let contentOffsetBottom = scrollView.contentOffset.y + scrollView.frame.size.height
        let contentSizeHeight = scrollView.contentSize.height
        return contentSizeHeight - contentOffsetBottom < 50
    }

    private func didScrollDown(contentOffset : CGPoint, _ prevOffset : CGPoint) -> Bool {
        let contentOffsetY = contentOffset.y
        let prevOffsetY = prevOffset.y
        return contentOffsetY > prevOffsetY
    }

    private func isAtTop(scrollView : UIScrollView) -> Bool {
        let contentOffsetTop = scrollView.contentOffset.y
        return contentOffsetTop < 0
    }

    private func isAtBottom(scrollView : UIScrollView) -> Bool {
        let contentOffsetBottom = scrollView.contentOffset.y + scrollView.frame.size.height
        let contentSizeHeight = scrollView.contentSize.height
        return contentOffsetBottom > contentSizeHeight
    }

    private func movedALittle(contentOffset : CGPoint, _ prevOffset : CGPoint) -> Bool {
        return prevOffset.y - contentOffset.y < 5
    }

    private func movedALot(contentOffset : CGPoint, _ prevOffset : CGPoint) -> Bool {
        return prevOffset.y - contentOffset.y > 10
    }

}