//Copyright © 2018 Inloop, s.r.o. All rights reserved.

import UIKit

public protocol DrawerConfiguration: class {
    func topPositionY(for parentHeight: CGFloat) -> CGFloat
    ///If you return nil, there will only be two positions, top and bottom
    func middlePositionY(for parentHeight: CGFloat) -> CGFloat?
    func bottomPositionY(for parentHeight: CGFloat) -> CGFloat
    /**
     drawerDismissClosure is injected by this lib.
     You should not change it, and you should call it when user presses dismiss button in your content view controller.
     It will hide the drawer.
     */
    var drawerDismissClosure: (() -> Void)? { get set }
    /**
    didChangeLayoutClosure is injected by this lib.
    You should not change it, and you should call it in didLayoutSubviews() method of your content view controller.
     It will update the drawer size to accomodate for your controller's new layout.
     */
    var didChangeLayoutClosure: (() -> Void)? { get set }
    /** You have to add UIPanGestureRecognizer somewhere to your drawer view controller.
     Then, in this method you are handed a pan gesture handler.
     You must (!!!) add it to your recognizer, and keep a strong reference (!!!) to this object
     */
    func setPanGestureTarget(_ target: Any, action: Selector)
}

public protocol DrawerPositionDelegate: class {
    func didMoveDrawerToTopPosition()
    func didMoveDrawerToMiddlePosition()
    func didMoveDrawerToBasePosition()
    func willDismissDrawer()
    func didDismissDrawer()
}

extension UIViewController {
    public func displayInDrawer(_ controller: UIViewController & DrawerConfiguration, drawerPositionDelegate: DrawerPositionDelegate?) {
        let cornerRadius: CGFloat = 10
        ///How much blank space is inserted at bottom
        let bottomOverpullPaddingHeight: CGFloat = 130
        let containerView = view.addContainerView(
            for: controller, cornerRadius:
            cornerRadius, bottomPaddingHeight:
            bottomOverpullPaddingHeight
        )
        /*
         Warning: when you add any decoration views, make sure, that their content is masked not to cover blur effect view.
         Otherwise it can mess up the visual blur effect.
         */
        let dimmingView = containerView.addDimmingView(cornerRadius: cornerRadius, canvasFrame: view.frame)
        containerView.addShadowBorderView(cornerRadius: cornerRadius, canvasFrame: view.frame)
        containerView.addDrawerHandleView(canvasFrame: view.frame)
        let panGestureTarget = PanGestureTarget(
            canvasView: view,
            drawerContainerView: containerView,
            dimmingView: dimmingView,
            drawerConfiguration: controller,
            drawerPositionDelegate: drawerPositionDelegate
        )
        controller.setPanGestureTarget(panGestureTarget, action: #selector(PanGestureTarget.userDidPan(recognizer:)))
        controller.drawerDismissClosure = { [weak self, weak containerView, weak drawerPositionDelegate] in
            guard let strongContainerView = containerView else { return }
            self?.dismissDrawerViewController(in: strongContainerView,
                                              dimmingView: dimmingView,
                                              drawerPositionDelegate: drawerPositionDelegate
            )
        }
        let initialDisplayAnimator = makeInitialDisplayAnimator(drawerConfiguration: controller,
                                                                containerView: containerView,
                                                                positionDelegate: drawerPositionDelegate
        )
        controller.didChangeLayoutClosure = didChangeLayoutClosure(
            containerView: containerView,
            initialDisplayAnimator: initialDisplayAnimator,
            panGestureTarget: panGestureTarget,
            bottomOverpullPaddingHeight: bottomOverpullPaddingHeight
        )
        embed(controller: controller, in: containerView, bottomPadding: bottomOverpullPaddingHeight)
        initialDisplayAnimator.startAnimation()
    }

    private func didChangeLayoutClosure(containerView: UIView,
                                        initialDisplayAnimator: UIViewPropertyAnimator,
                                        panGestureTarget: PanGestureTarget,
                                        bottomOverpullPaddingHeight: CGFloat) -> () -> Void {
        return { [weak self, weak containerView, weak initialDisplayAnimator] in
            guard let strongSelf = self, let strongContainerView = containerView else { return }
            let oldTopPositionY = panGestureTarget.topPositionY!
            let oldMiddlePositionY = panGestureTarget.middlePositionY
            let oldBasePositionY = panGestureTarget.bottomPositionY!
            panGestureTarget.refreshDrawerPositions()
            let newContainerHeight = strongSelf.view.bounds.height - panGestureTarget.topPositionY + bottomOverpullPaddingHeight
            if strongContainerView.frame.height != newContainerHeight {
                dLog("containerViewFrame changed from: \(strongContainerView.frame)")
                strongContainerView.frame.size.height = newContainerHeight
                dLog("containerViewFrame changed to: \(strongContainerView.frame)")
            }

            let isOnOldTopPosition = Int(strongContainerView.frame.minY) == Int(oldTopPositionY)
            let newTopPositionIsDifferentThanOld = Int(panGestureTarget.topPositionY) != Int(oldTopPositionY)

            let isOnOldMiddlePosition: Bool
            let newMiddlePositionIsDifferentThanOld: Bool
            if let oldMiddlePositionY = oldMiddlePositionY, let newMiddlePositionY = panGestureTarget.middlePositionY {
                isOnOldMiddlePosition = Int(strongContainerView.frame.minY) == Int(oldMiddlePositionY)
                newMiddlePositionIsDifferentThanOld = Int(newMiddlePositionY) != Int(oldMiddlePositionY)
            } else {
                isOnOldMiddlePosition = false
                newMiddlePositionIsDifferentThanOld = false
            }

            let isOnOldBottomPosition = Int(strongContainerView.frame.minY) == Int(oldBasePositionY)
            let newBottomPositionIsDifferentThanOld = Int(panGestureTarget.bottomPositionY) != Int(oldBasePositionY)

            let isInitialDisplayAnimation = initialDisplayAnimator != nil

            if !isInitialDisplayAnimation && isOnOldTopPosition && newTopPositionIsDifferentThanOld {
                self?.updateDrawerPosition(
                    inFlightAnimator: initialDisplayAnimator,
                    newTargetY: panGestureTarget.topPositionY,
                    containerView: strongContainerView
                )
            } else if !isInitialDisplayAnimation && isOnOldMiddlePosition && newMiddlePositionIsDifferentThanOld {
                self?.updateDrawerPosition(
                    inFlightAnimator: initialDisplayAnimator,
                    newTargetY: panGestureTarget.middlePositionY ?? panGestureTarget.bottomPositionY,
                    containerView: strongContainerView
                )
            } else if isOnOldBottomPosition && newBottomPositionIsDifferentThanOld {
                self?.updateDrawerPosition(
                    inFlightAnimator: initialDisplayAnimator,
                    newTargetY: panGestureTarget.bottomPositionY,
                    containerView: strongContainerView
                )
            }
        }
    }

    private func embed(controller: UIViewController, in containerView: UIView, bottomPadding: CGFloat) {
        addChild(controller)
        containerView.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        let views = ["v": controller.view!]
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]-\(bottomPadding)-|", metrics: nil, views: views)
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|", metrics: nil, views: views)
        NSLayoutConstraint.activate(vertical + horizontal)
        controller.didMove(toParent: self)
    }

    private func updateDrawerPosition(inFlightAnimator: UIViewPropertyAnimator?, newTargetY: CGFloat, containerView: UIView) {
        dLog("inFlightAnimator: \(String(describing: inFlightAnimator))")
        var newFrame = containerView.frame
        newFrame.origin.y = newTargetY
        if let animator = inFlightAnimator {
            animator.addAnimations { containerView.frame = newFrame }
        } else {
            containerView.frame = newFrame
        }
    }

    private func makeInitialDisplayAnimator(drawerConfiguration: DrawerConfiguration,
                                            containerView: UIView,
                                            positionDelegate: DrawerPositionDelegate?) -> UIViewPropertyAnimator {
        var endFrame = containerView.frame
        endFrame.origin.y = drawerConfiguration.bottomPositionY(for: view.bounds.height)
        let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut, animations: {
            containerView.frame = endFrame
        })
        animator.addCompletion({ status in
            if status == UIViewAnimatingPosition.end {
                positionDelegate?.didMoveDrawerToBasePosition()
            }
        })
        return animator
    }

    private func dismissDrawerViewController(in containerView: UIView,
                                             dimmingView: UIView,
                                             drawerPositionDelegate: DrawerPositionDelegate?) {
        let currentFrame = containerView.frame
        var targetFrame = currentFrame
        targetFrame.origin.y = containerView.superview!.bounds.height
        drawerPositionDelegate?.willDismissDrawer()
        UIView.animate(
            withDuration: 0.25,
            animations: {
                containerView.frame = targetFrame
                dimmingView.alpha = 0
        },
            completion: { _ in
                drawerPositionDelegate?.didDismissDrawer()
                self.removeChildViewController(from: containerView)
                containerView.removeFromSuperview()
        })
    }

    
    private func removeChildViewController(from containerView: UIView) {
        let child = childViewController(at: containerView)
        child?.willMove(toParent: nil)
        child?.view.removeFromSuperview()
        child?.removeFromParent()
    }
    private func childViewController(at containerView: UIView) -> UIViewController? {
        return children.first(where: { containerView.subviews.contains($0.view) })
    }
}

private extension UIView {
    func addContainerView(for drawerConfiguration: DrawerConfiguration, cornerRadius: CGFloat, bottomPaddingHeight: CGFloat) -> UIView {
        var startFrame = bounds
        startFrame.size.height = bounds.height - drawerConfiguration.topPositionY(for: bounds.height) + bottomPaddingHeight
        startFrame.origin.y += bounds.height
        /*
         OutsideBoundsHittableView is used here so that we capture taps on dimmed background.
         They should not fall through to underlying controller.
         */
        let containerView = OutsideBoundsHittableView(frame: startFrame)
        containerView.preservesSuperviewLayoutMargins = true
        addSubview(containerView)
        let effect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
        let containerEffectView = UIVisualEffectView(effect: effect)
        containerEffectView.frame = containerView.bounds
        containerEffectView.layer.cornerRadius = cornerRadius
        containerEffectView.clipsToBounds = true
        containerView.pinSubview(containerEffectView)
        return containerView
    }

    func addDimmingView(cornerRadius: CGFloat, canvasFrame: CGRect) -> UIView {
        var dimViewFrame = canvasFrame
        dimViewFrame.size.height += cornerRadius
        //we are going to add to the top of containerView, but behind rounded corners
        dimViewFrame.origin.y = cornerRadius - dimViewFrame.height
        let result = UIView(frame: dimViewFrame)
        result.backgroundColor = .black
        result.alpha = 0
        result.addBottomRoundedCornersMask(cornerRadius: cornerRadius)
        addSubview(result)
        return result
    }

    func addShadowBorderView(cornerRadius: CGFloat, canvasFrame: CGRect) {
        let shadowHeight: CGFloat = 15
        let frame = CGRect(x: 0, y: -shadowHeight, width: canvasFrame.width, height: cornerRadius + shadowHeight)
        let result = UIView(frame: frame)
        result.backgroundColor = .clear
        result.addBottomRoundedCornersMask(cornerRadius: cornerRadius)
        result.addBottomBorderWithShadow(cornerRadius: cornerRadius)
        addSubview(result)
    }

    func addDrawerHandleView(canvasFrame: CGRect) {
        let handleSize = CGSize(width: 36, height: 3.5)
        let origin = CGPoint(x: canvasFrame.width/2 - handleSize.width/2, y: 6)
        let frame = CGRect(origin: origin, size: handleSize)
        let result = UIView(frame: frame)
        result.backgroundColor = UIColor(red: 203.0/255, green: 205.0/255, blue: 204.0/255, alpha: 0.5)
        result.layer.cornerRadius = 3.5
        addSubview(result)
    }

    func addBottomRoundedCornersMask(cornerRadius: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: frame.height))
        path.addArc(
            withCenter: CGPoint(x: cornerRadius, y: frame.height),
            radius: cornerRadius,
            startAngle: CGFloat.pi, // straight left
            endAngle: 3*CGFloat.pi/2, // up
            clockwise: true
        )
        path.addLine(to: CGPoint(x: frame.width - cornerRadius, y: frame.height - cornerRadius))
        path.addArc(
            withCenter: CGPoint(x: frame.width - cornerRadius, y: frame.height),
            radius: cornerRadius,
            startAngle: 3*CGFloat.pi/2,
            endAngle: 2*CGFloat.pi, clockwise: true)
        path.addLine(to: CGPoint(x: frame.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))

        let layer = CAShapeLayer()
        layer.path = path.cgPath
        self.layer.mask = layer
    }

    func addBottomBorderWithShadow(cornerRadius: CGFloat) {
        let borderWidth: CGFloat = 0.5
        let shadowPath = UIBezierPath()
        shadowPath.move(to: CGPoint(x: 0, y: frame.height - borderWidth/2))
        shadowPath.addArc(
            withCenter: CGPoint(x: cornerRadius, y: frame.height - borderWidth/2),
            radius: cornerRadius,
            startAngle: CGFloat.pi, // straight left
            endAngle: 3*CGFloat.pi/2, // up
            clockwise: true
        )
        shadowPath.addLine(to: CGPoint(x: frame.width - cornerRadius, y: frame.height - cornerRadius - borderWidth/2))
        shadowPath.addArc(
            withCenter: CGPoint(x: frame.width - cornerRadius, y: frame.height - borderWidth/2),
            radius: cornerRadius,
            startAngle: 3*CGFloat.pi/2,
            endAngle: 2*CGFloat.pi,
            clockwise: true
        )
        let shadowLayer = CAShapeLayer()
        shadowLayer.path = shadowPath.cgPath
        shadowLayer.strokeColor = UIColor(red: 205.0/255, green: 206.0/255, blue: 210.0/255, alpha: 0.8).cgColor
        shadowLayer.lineWidth = borderWidth
        shadowLayer.fillColor = UIColor.clear.cgColor
        shadowLayer.shadowOffset = CGSize(width: 0, height: -0.5)
        shadowLayer.shadowRadius = 2
        shadowLayer.shadowColor = UIColor.black.cgColor
        shadowLayer.shadowOpacity = 0.45
        layer.addSublayer(shadowLayer)
    }
}
