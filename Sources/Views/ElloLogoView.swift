////
///  ElloLogoView.swift
//

import QuartzCore
import FLAnimatedImage
import CoreGraphics

open class ElloLogoView: UIImageView {

    public enum Config {
        case normal
        case grey

        var image: UIImage {
            switch self {
            case .normal: return InterfaceImage.elloLogo.normalImage
            case .grey: return InterfaceImage.elloLogoGrey.normalImage
            }
        }
    }

    struct Size {
        static let Natural = CGSize(width: 60, height: 60)
    }

    fileprivate var wasAnimating = false
    fileprivate var config: ElloLogoView.Config = .normal

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience public init() {
        self.init(frame: .zero)
    }

    convenience public init(config: ElloLogoView.Config) {
        self.init(frame: .zero)
        self.config = config
        self.image = self.config.image
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.image = self.config.image
        self.contentMode = .scaleAspectFit
    }

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && wasAnimating {
            animateLogo()
        }
    }

    func animateLogo() {
        wasAnimating = true

        self.layer.removeAnimation(forKey: "logo-spin")
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        let angle = layer.value(forKeyPath: "transform.rotation.z") as! NSNumber
        rotate.fromValue = angle
        rotate.toValue = 2 * M_PI
        rotate.duration = 0.35
        rotate.repeatCount = 1_000_000
        self.layer.add(rotate, forKey: "logo-spin")
    }

    func stopAnimatingLogo() {
        wasAnimating = false

        self.layer.removeAllAnimations()

        let endAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        if let layer = self.layer.presentation() {
            let angle = layer.value(forKeyPath: "transform.rotation.z") as! NSNumber
            endAnimation.fromValue = angle.floatValue
            endAnimation.toValue = 0
            endAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            endAnimation.duration = 0.25
        }
        self.layer.add(endAnimation, forKey: "logo-spin")
    }
}
