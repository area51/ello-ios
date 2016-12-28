////
///  DrawerPopControl.swift
//

open class DrawerPopControl: UIControl {
    var presentingController: UIViewController?

    public init() {
        super.init(frame: .zero)
        addTarget(self, action: #selector(DrawerPopControl.pop), for: .touchDown)
    }

    func pop() {
        presentingController?.dismiss(animated: true, completion: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
