////
///  Rate.swift
//

import Foundation
import iRate

open class Rate: NSObject {

    open static let sharedRate = Rate()

    open func setup() {
        iRate.sharedInstance().delegate = self
        iRate.sharedInstance().onlyPromptIfLatestVersion = true
        iRate.sharedInstance().previewMode = false
        iRate.sharedInstance().messageTitle = InterfaceString.Rate.Title
        iRate.sharedInstance().message = ""
        iRate.sharedInstance().updateMessage = ""
        iRate.sharedInstance().rateButtonLabel = InterfaceString.Rate.Continue
        iRate.sharedInstance().cancelButtonLabel = InterfaceString.Rate.Cancel
        iRate.sharedInstance().usesUntilPrompt = 3
        iRate.sharedInstance().eventsUntilPrompt = 3
        iRate.sharedInstance().daysUntilPrompt = 7
        iRate.sharedInstance().usesPerWeekForPrompt = 0
        iRate.sharedInstance().remindPeriod = 7
    }

    open func prompt() {
        iRate.sharedInstance().promptForRating()
    }

    open func logEvent() {
        iRate.sharedInstance().logEvent(false)
    }
}

extension Rate: iRateDelegate {
    public func iRateCouldNotConnect(toAppStore error: Error!){
        Tracker.sharedTracker.ratePromptCouldNotConnectToAppStore()
    }

    public func iRateDidPromptForRating(){
        Tracker.sharedTracker.ratePromptShown()
    }

    public func iRateUserDidAttemptToRateApp(){
        Tracker.sharedTracker.ratePromptUserAttemptedToRateApp()
    }

    public func iRateUserDidDeclineToRateApp(){
        Tracker.sharedTracker.ratePromptUserDeclinedToRateApp()
    }

    public func iRateUserDidRequestReminderToRateApp(){
        Tracker.sharedTracker.ratePromptRemindMeLater()
    }

    public func iRateDidOpenAppStore(){
        Tracker.sharedTracker.ratePromptOpenedAppStore()
    }
}
