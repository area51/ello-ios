////
///  StreamableScreen.swift
//

public protocol StreamableScreenProtocol: class {
    var navigationBarTopConstraint: NSLayoutConstraint! { get }
    var navigationBar: ElloNavigationBar { get }
    var navigationItem: UINavigationItem? { get set }
}

open class StreamableScreen: Screen, StreamableScreenProtocol {
    open let navigationBar = ElloNavigationBar()
    open var navigationBarTopConstraint: NSLayoutConstraint!
    let streamContainer = UIView()

    open var navigationItem: UINavigationItem? {
        get { return navigationBar.items?.first }
        set {
            navigationBar.items = newValue.flatMap { [$0] }
        }
    }

    convenience init() {
        self.init(frame: UIScreen.main.bounds)
    }

    override func arrange() {
        super.arrange()

        addSubview(streamContainer)
        addSubview(navigationBar)

        navigationBar.snp.makeConstraints { make in
            let c = make.top.equalTo(self).constraint
            self.navigationBarTopConstraint = c.layoutConstraints.first!
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        streamContainer.snp.makeConstraints { make in
            make.edges.equalTo(self)
            streamContainer.frame = self.bounds
        }

        layoutIfNeeded()
    }
}
