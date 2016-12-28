////
///  StreamFooterCell.swift
//

let streamCellDidOpenNotification = TypedNotification<UICollectionViewCell>(name: "StreamCellDidOpenNotification")

open class StreamFooterCell: UICollectionViewCell {
    static let reuseIdentifier = "StreamFooterCell"

    @IBOutlet weak open var toolBar: UIToolbar!
    @IBOutlet weak open var containerView: UIView!
    @IBOutlet weak open var innerContentView: UIView!

    open var commentsOpened = false
    open weak var delegate: PostbarDelegate?
    open weak var streamEditingDelegate: StreamEditingDelegate?

    open let viewsItem = ElloPostToolBarOption.views.barButtonItem()
    open var viewsControl: ImageLabelControl {
        return self.viewsItem.customView as! ImageLabelControl
    }

    open let lovesItem = ElloPostToolBarOption.loves.barButtonItem()
    open var lovesControl: ImageLabelControl {
        return self.lovesItem.customView as! ImageLabelControl
    }

    open let commentsItem = ElloPostToolBarOption.comments.barButtonItem()
    open var commentsControl: ImageLabelControl {
        return self.commentsItem.customView as! ImageLabelControl
    }

    open let repostItem = ElloPostToolBarOption.repost.barButtonItem()
    open var repostControl: ImageLabelControl {
        return self.repostItem.customView as! ImageLabelControl
    }

    open let shareItem = ElloPostToolBarOption.share.barButtonItem()
    open var shareControl: ImageLabelControl {
        return self.shareItem.customView as! ImageLabelControl
    }

    open let replyItem = ElloPostToolBarOption.reply.barButtonItem()
    open var replyControl: ImageLabelControl {
        return self.replyItem.customView as! ImageLabelControl
    }

    fileprivate func updateButtonVisibility(_ button: UIControl, visibility: InteractionVisibility) {
        button.isHidden = !visibility.isVisible
        button.isEnabled = visibility.isEnabled
        button.isSelected = visibility.isSelected
    }

    open func updateToolbarItems(
        streamKind: StreamKind,
        repostVisibility: InteractionVisibility,
        commentVisibility: InteractionVisibility,
        shareVisibility: InteractionVisibility,
        loveVisibility: InteractionVisibility
        )
    {
        updateButtonVisibility(self.repostControl, visibility: repostVisibility)
        updateButtonVisibility(self.lovesControl, visibility: loveVisibility)
        var toolbarItems: [UIBarButtonItem] = []

        let desiredCount: Int
        if streamKind.isGridView {
            desiredCount = 3

            if commentVisibility.isVisible {
                toolbarItems.append(commentsItem)
            }

            if loveVisibility.isVisible {
                toolbarItems.append(lovesItem)
            }

            if repostVisibility.isVisible {
                toolbarItems.append(repostItem)
            }
        }
        else {
            desiredCount = 5

            toolbarItems.append(viewsItem)

            if commentVisibility.isVisible {
                toolbarItems.append(commentsItem)
            }

            if loveVisibility.isVisible {
                toolbarItems.append(lovesItem)
            }

            if repostVisibility.isVisible {
                toolbarItems.append(repostItem)
            }

            if shareVisibility.isVisible {
                toolbarItems.append(shareItem)
            }
        }

        while toolbarItems.count < desiredCount {
            toolbarItems.append(fixedItem(44))
        }
        self.toolBar.items = Array(toolbarItems.flatMap { [self.flexibleItem(), $0] }.dropFirst())
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        toolBar.isTranslucent = false
        toolBar.barTintColor = UIColor.white
        toolBar.clipsToBounds = true
        toolBar.layer.borderColor = UIColor.white.cgColor

        let longPressGesture = UILongPressGestureRecognizer()
        longPressGesture.addTarget(self, action: #selector(longPressed(_:)))
        contentView.addGestureRecognizer(longPressGesture)

        addButtonHandlers()
    }

    open var views: String? {
        get { return viewsControl.title }
        set { viewsControl.title = newValue }
    }

    open var comments: String? {
        get { return commentsControl.title }
        set { commentsControl.title = newValue }
    }

    open var loves: String? {
        get { return lovesControl.title }
        set { lovesControl.title = newValue }
    }

    open var reposts: String? {
        get { return repostControl.title }
        set { repostControl.title = newValue }
    }

// MARK: - Private

    fileprivate func fixedItem(_ width: CGFloat) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        item.width = width
        return item
    }

    fileprivate func flexibleItem() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }

    fileprivate func addButtonHandlers() {
        commentsControl.addTarget(self, action: #selector(StreamFooterCell.commentsButtonTapped), for: .touchUpInside)
        lovesControl.addTarget(self, action: #selector(StreamFooterCell.lovesButtonTapped), for: .touchUpInside)
        replyControl.addTarget(self, action: #selector(StreamFooterCell.replyButtonTapped), for: .touchUpInside)
        repostControl.addTarget(self, action: #selector(StreamFooterCell.repostButtonTapped), for: .touchUpInside)
        shareControl.addTarget(self, action: #selector(StreamFooterCell.shareButtonTapped), for: .touchUpInside)
        viewsControl.addTarget(self, action: #selector(StreamFooterCell.viewsButtonTapped), for: .touchUpInside)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        let newBounds = CGRect(x: 0, y: 0, width: bounds.width, height: 44)
        contentView.frame = newBounds
        innerContentView.frame = newBounds
        containerView.frame = newBounds
        toolBar.frame = newBounds
    }

// MARK: - IBActions

    @IBAction func viewsButtonTapped() {
        guard let indexPath = indexPath else { return }
        delegate?.viewsButtonTapped(indexPath)
    }

    @IBAction func commentsButtonTapped() {
        commentsOpened = !commentsOpened
        delegate?.commentsButtonTapped(self, imageLabelControl: commentsControl)
    }

    func cancelCommentLoading() {
        commentsControl.isEnabled = true
        commentsControl.finishAnimation()
        commentsControl.isSelected = false
        commentsOpened = false
    }

    @IBAction func lovesButtonTapped() {
        guard let indexPath = indexPath else { return }
        delegate?.lovesButtonTapped(self, indexPath: indexPath)
    }

    @IBAction func repostButtonTapped() {
        guard let indexPath = indexPath else { return }
        delegate?.repostButtonTapped(indexPath)
    }

    @IBAction func shareButtonTapped() {
        guard let indexPath = indexPath else { return }
        delegate?.shareButtonTapped(indexPath, sourceView: shareControl)
    }

    @IBAction func replyButtonTapped() {
    }

    @IBAction func longPressed(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            streamEditingDelegate?.cellLongPressed(cell: self)
        }
    }
}
