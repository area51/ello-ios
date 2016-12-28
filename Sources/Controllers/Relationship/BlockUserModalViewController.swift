////
///  BlockUserModalViewController.swift
//

import Foundation
import SnapKit


open class BlockUserModalViewController: BaseElloViewController, BlockUserModalDelegate {
    weak open var relationshipDelegate: RelationshipDelegate?

    let config: BlockUserModalConfig
    var relationshipPriority: RelationshipPriority { return config.relationshipPriority }
    var userId: String { return config.userId }
    var userAtName: String { return config.userAtName }
    var changeClosure: RelationshipChangeClosure { return config.changeClosure }

    var screen: BlockUserModalScreen { return self.view as! BlockUserModalScreen }

    required public init(config: BlockUserModalConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        let screen = BlockUserModalScreen(config: config)
        self.view = screen
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let superView = self.view.superview {
            self.view.center = superView.center
        }
    }

    open func updateRelationship(_ newRelationship: RelationshipPriority) {
        guard let currentUserId = currentUser?.id else {
            closeModal()
            return
        }

        switch newRelationship {
            case .block: Tracker.sharedTracker.userBlocked(userId)
            case .mute: Tracker.sharedTracker.userMuted(userId)
            case .inactive:
                if relationshipPriority == .block {
                    Tracker.sharedTracker.userUnblocked(userId)
                }
                else if relationshipPriority == .mute {
                    Tracker.sharedTracker.userUnmuted(userId)
                }
            default: break
        }

        relationshipDelegate?.updateRelationship(currentUserId, userId: userId, prev: relationshipPriority, relationshipPriority: newRelationship) {
            (status, relationship, isFinalValue) in
            switch status {
            case .success:
                self.changeClosure(newRelationship)
                self.closeModal()
            case .failure:
                self.changeClosure(self.relationshipPriority)
            }
        }
    }

    open func flagTapped() {
        if let presentingViewController = presentingViewController {
            let flagger = ContentFlagger(
                presentingController: presentingViewController,
                flaggableId: userId,
                contentType: .user
            )

            closeModalAndThen {
                flagger.displayFlaggingSheet()
            }
        }
    }

    open func closeModal() {
        closeModalAndThen {}
    }

    open func closeModalAndThen(_ completion: @escaping BasicBlock) {
        Tracker.sharedTracker.userBlockCanceled(userId)
        self.dismiss(animated: true, completion: completion)
    }

}
