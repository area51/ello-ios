////
///  AutoCompleteViewController.swift
//


public protocol AutoCompleteDelegate: NSObjectProtocol {
    func autoComplete(_ controller: AutoCompleteViewController, itemSelected item: AutoCompleteItem)
}

open class AutoCompleteViewController: UIViewController {
    @IBOutlet weak open var tableView: UITableView!
    open let dataSource = AutoCompleteDataSource()
    open let service = AutoCompleteService()
    open weak var delegate: AutoCompleteDelegate?

    required public init() {
        super.init(nibName: "AutoCompleteViewController", bundle: .none)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: View Lifecycle
extension AutoCompleteViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = dataSource
        registerCells()
        style()
    }
}


// MARK: Public
public extension AutoCompleteViewController {

    func load(_ match: AutoCompleteMatch, loaded: @escaping (_ count: Int) -> Void) {
        switch match.type {
        case .emoji:
            let results: [AutoCompleteResult] = service.loadEmojiResults(match.text)
            self.dataSource.items = results.map { AutoCompleteItem(result: $0, type: match.type, match: match) }
            self.tableView.reloadData()
            loaded(self.dataSource.items.count)
        case .username:
            service.loadUsernameResults(match.text,
                success: { (results, _) in
                    self.dataSource.items = results.map { AutoCompleteItem(result: $0, type: match.type, match: match) }
                    self.tableView.reloadData()
                    loaded(self.dataSource.items.count)
                }, failure: showAutoCompleteLoadFailure)
        case .location:
            service.loadLocationResults(match.text,
                success: { (results, _) in
                    self.dataSource.items = results.map { AutoCompleteItem(result: $0, type: match.type, match: match) }
                    self.tableView.reloadData()
                    loaded(self.dataSource.items.count)
                }, failure: showAutoCompleteLoadFailure)
        }
    }

    func showAutoCompleteLoadFailure(_ error: NSError, statusCode: Int?) {
        let message = InterfaceString.GenericError
        let alertController = AlertViewController(message: message)
        let action = AlertAction(title: InterfaceString.OK, style: .dark, handler: nil)
        alertController.addAction(action)
        logPresentingAlert("AutoCompleteViewController")
        present(alertController, animated: true) {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: UITableViewDelegate
extension AutoCompleteViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = dataSource.itemForIndexPath(indexPath) {
            delegate?.autoComplete(self, itemSelected: item)
        }
    }
}


// MARK: Private
private extension AutoCompleteViewController {
    func registerCells() {
        tableView.register(AutoCompleteCell.nib(), forCellReuseIdentifier: AutoCompleteCell.reuseIdentifier)
    }

    func style() {
        tableView.backgroundColor = UIColor.black
    }
}
