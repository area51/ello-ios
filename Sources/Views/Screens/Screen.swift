////
///  Screen.swift
//

import SnapKit


/// Easy keyboard views: pin an anchor to `keyboardAnchor.top`. It'll animate automatically, too.
public class Screen: UIView {
    let keyboardAnchor = UIView()
    private var keyboardTopConstraint: Constraint!
    private var keyboardWillShowObserver: NotificationObserver?
    private var keyboardWillHideObserver: NotificationObserver?

    convenience init() {
        self.init(frame: UIScreen.mainScreen().bounds)
    }

    public required override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(keyboardAnchor)
        backgroundColor = .whiteColor()

        screenInit()
        style()
        bindActions()
        setText()
        arrange()

        // for controllers that use "container" views, they need to be set to the correct dimensions,
        // otherwise there'll be constraint violations.
        layoutIfNeeded()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        teardownKeyboardObservers()
    }

    override public func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)

        if newWindow != nil && window == nil {
            setupKeyboardObservers()
        }
        else if newWindow == nil && window != nil {
            teardownKeyboardObservers()
        }
    }

    private func setupKeyboardObservers() {
        keyboardWillShowObserver = NotificationObserver(notification: Keyboard.Notifications.KeyboardWillShow, block: keyboardWillChange)
        keyboardWillHideObserver = NotificationObserver(notification: Keyboard.Notifications.KeyboardWillHide, block: keyboardWillChange)
    }

    private func teardownKeyboardObservers() {
        keyboardWillShowObserver?.removeObserver()
        keyboardWillHideObserver?.removeObserver()
        keyboardWillShowObserver = nil
        keyboardWillHideObserver = nil
    }

    func keyboardWillChange(keyboard: Keyboard) {
        let bottomInset = keyboard.keyboardBottomInset(inView: self)
        animate(duration: keyboard.duration, options: keyboard.options, completion: { _ in self.keyboardDidAnimate() }) {
            self.keyboardTopConstraint.updateOffset(-bottomInset)
            self.keyboardIsAnimating(keyboard)
            self.layoutIfNeeded()
        }
    }

    public func keyboardIsAnimating(keyboard: Keyboard) {}
    public func keyboardDidAnimate() {}

    func screenInit() {}
    func style() {}
    func bindActions() {}
    func setText() {}
    func arrange() {
        keyboardAnchor.snp_makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            keyboardTopConstraint = make.top.equalTo(self.snp_bottom).constraint
        }
    }
}
