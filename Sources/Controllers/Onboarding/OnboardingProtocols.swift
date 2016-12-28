////
///  OnboardingProtocols.swift
//

public enum OnboardingStep: Int {
    case categories = 0
    case createProfile
    case inviteFriends
}

public protocol OnboardingDelegate: class {
    func nextAction()
    func abortAction()
}

public protocol OnboardingScreenProtocol: class {
    var delegate: OnboardingDelegate? { get set }
    var controllerContainer: UIView { get set }
    var hasAbortButton: Bool { get set }
    var canGoNext: Bool { get set }
    var prompt: String? { get set }
    func styleFor(step: OnboardingStep)
}

public protocol OnboardingStepController: class {
    var onboardingViewController: OnboardingViewController? { get set }
    var onboardingData: OnboardingData! { get set }
    func onboardingWillProceed(abort: Bool, proceedClosure: @escaping (_ success: OnboardingViewController.OnboardingProceed) -> Void)
    func onboardingStepBegin()
}
