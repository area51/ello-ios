////
///  ElloCollectionView.swift
//

import UIKit


//
// This `contentInset` nonsense is to prevent UIKit from setting the content
// inset when we don't want it to.  Setting `automaticallyAdjustsContentInsets`
// to `false` *should* prevent this from happening, but it doesn't.  So instead,
// the `StreamViewController` sets `elloContentInset`.  If `contentInset` is
// set outside the scope of `uikitOverride` being set, it will be *restored* to
// whatever `elloContentInset` was set to.
//
// UG
//
open class ElloCollectionView: UICollectionView {
    fileprivate var uikitOverride = false
    open var elloContentInset: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            uikitOverride = true
            contentInset = elloContentInset
            uikitOverride = false
        }
    }
    override open var contentInset: UIEdgeInsets {
        didSet {
            if !uikitOverride {
                uikitOverride = true
                contentInset = elloContentInset
                uikitOverride = false
            }
        }
    }
}
