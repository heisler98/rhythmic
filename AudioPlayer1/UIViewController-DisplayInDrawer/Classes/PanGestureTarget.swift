//Copyright © 2018 Inloop, s.r.o. All rights reserved.

import UIKit

final class PanGestureTarget {
    /**
     Speed of user movement which triggers spring damping animation
     when view lands at the target drawer position
     */
    private let bounceVelocityThreshold: CGFloat = 100
    private let skipMiddleVelocityThreshold: CGFloat = 1500
    private let animationDuration: TimeInterval = 0.25
    private let dampedAnimationDuration: TimeInterval = 0.4
    private let springAnimationDamping: CGFloat = 0.75
    private let targetDimmingViewAlpha: CGFloat = 0.4 // system alert dimming alpha
    /**
     Determines rubber bound behaviour when you drag out of bounds.
     0 means no resistance, 1 means infinite resistance (no movement)
     */
    private let rubberConstant: CGFloat = 0.75
    /// The view of the presenting controller
    private weak var canvasView: UIView!
    private weak var drawerContainerView: UIView!
    private weak var dimmingView: UIView!
    private weak var drawerConfiguration: DrawerConfiguration?
    private weak var drawerPositionDelegate: DrawerPositionDelegate?
    private var initialDrawerCenterLocation: CGPoint = .zero
    var topPositionY: CGFloat!
    var middlePositionY: CGFloat?
    var bottomPositionY: CGFloat!

    init(canvasView: UIView,
         drawerContainerView: UIView,
         dimmingView: UIView,
         drawerConfiguration: DrawerConfiguration,
         drawerPositionDelegate: DrawerPositionDelegate?) {
        self.canvasView = canvasView
        self.drawerContainerView = drawerContainerView
        self.dimmingView = dimmingView
        self.drawerConfiguration = drawerConfiguration
        self.drawerPositionDelegate = drawerPositionDelegate
        refreshDrawerPositions()
    }

    internal func refreshDrawerPositions() {
        bottomPositionY = drawerConfiguration?.bottomPositionY(for: canvasView.bounds.height) ?? 0
        topPositionY = drawerConfiguration?.topPositionY(for: canvasView.bounds.height) ?? 0
        middlePositionY = drawerConfiguration?.middlePositionY(for: canvasView.bounds.height)
    }

    deinit {
        dLog("$$$$$$ PanGestureTarget")
    }

    @objc func userDidPan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            initialDrawerCenterLocation = drawerContainerView.center
        } else if recognizer.state == .changed {
            performDrag(recognizer: recognizer)
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            let velocity = recognizer.velocity(in: canvasView)
            let targetPositionY = self.targetPositionY(for: velocity)
            animate(to: targetPositionY, velocity: velocity)
        }
    }

    private var isDraggedViewWithinAllowedArea: Bool {
        return drawerContainerView.frame.minY > topPositionY && drawerContainerView.frame.minY < bottomPositionY
    }

    private func performDrag(recognizer: UIPanGestureRecognizer) {
        let changeSincePanBegun = recognizer.translation(in: canvasView).y
        var newCenter = initialDrawerCenterLocation
        newCenter.y += changeSincePanBegun
        let overdraggedDistance = overDragAmount(newCenter)
        if overdraggedDistance != 0 {
            //subtract overdragged rubber bound (kind of)
            let dragDistanceToSubtract = overdraggedDistance * rubberConstant
            newCenter.y -= dragDistanceToSubtract
        }
        drawerContainerView.center = newCenter
        updateDimming()
    }

    private func updateDimming() {
        guard overDragAmount(drawerContainerView.center) == 0 else { return }
        let currentDistanceToDimStartPosition = dimStartPosition - drawerContainerView.frame.minY
        let totalDraggableDistance = dimStartPosition - topPositionY
        let movementPercentage = currentDistanceToDimStartPosition / totalDraggableDistance
        dimmingView.alpha = movementPercentage * targetDimmingViewAlpha
    }

    private var dimStartPosition: CGFloat {
        return middlePositionY ?? bottomPositionY
    }

    private func overDragAmount(_ newCenter: CGPoint) -> CGFloat {
        let newMinY = newCenter.y - drawerContainerView.frame.height/2
        let aboveTop = newMinY - topPositionY
        let underBottom = newMinY - bottomPositionY
        if aboveTop < 0 {
            return aboveTop
        } else if underBottom > 0 {
            return underBottom
        } else {
            return 0
        }
    }

    private func targetPositionY(for velocity: CGPoint) -> CGFloat {
        let isDraggingQuickly = abs(velocity.y) > skipMiddleVelocityThreshold
        let isDraggingSlowly = abs(velocity.y) < bounceVelocityThreshold
        let isDraggingUp = velocity.y < 0
        if isDraggingQuickly && isDraggingUp {
            return topPositionY
        } else if isDraggingQuickly && !isDraggingUp {
            return bottomPositionY
        } else if isDraggingSlowly {
            return nearestPosition(searchStyle: .nearest)
        } else if isDraggingUp {
            return nearestPosition(searchStyle: .higher)
        } else if !isDraggingUp {
            return nearestPosition(searchStyle: .lower)
        } else {
            fatalError()
        }
    }

    private enum NearestPositionSearchStyle {
        case nearest, higher, lower
    }

    private func nearestPosition(searchStyle: NearestPositionSearchStyle) -> CGFloat {
        let currentPosition = drawerContainerView.frame.minY
        switch searchStyle {
        case .nearest:
            return positionsArray.min(by: { abs(currentPosition - $0) < abs(currentPosition - $1) })!
        case .higher:
            /* Keep in mind, that higher position means lower Y in UIView coordinate system */
            return positionsArray.sorted(by: >).first(where: { currentPosition - $0 > 0 }) ?? topPositionY
        case .lower:
            /* Keep in mind, that lower position means higher Y in UIView coordinate system */
            return positionsArray.sorted(by: <).first(where: { $0 - currentPosition > 0 }) ?? bottomPositionY
        }
    }

    private var positionsArray: [CGFloat] {
        guard let middlePositionY = middlePositionY else { return [bottomPositionY, topPositionY] }
        return [bottomPositionY, middlePositionY, topPositionY]
    }

    private func animate(to minY: CGFloat, velocity: CGPoint) {
        var newFrame = drawerContainerView.frame
        newFrame.origin.y = minY
        let shouldBounce = abs(velocity.y) > bounceVelocityThreshold
        let targetDimmingAlpha = minY == topPositionY ? targetDimmingViewAlpha : CGFloat(0)
        let animationClosure = {
            self.drawerContainerView.frame = newFrame
            self.dimmingView.alpha = targetDimmingAlpha
        }
        let completionClosure: (Bool) -> Void = { finished in
            guard finished else { return }
            if self.isOnTopPosition {
                self.drawerPositionDelegate?.didMoveDrawerToTopPosition()
            } else if self.isOnMiddlePosition {
                self.drawerPositionDelegate?.didMoveDrawerToMiddlePosition()
            } else if self.isOnBasePosition {
                self.drawerPositionDelegate?.didMoveDrawerToBasePosition()
            }
        }
        if shouldBounce {
            UIView.animate(
                withDuration: dampedAnimationDuration,
                delay: 0,
                usingSpringWithDamping: springAnimationDamping,
                initialSpringVelocity: 0,
                options: [.curveEaseOut],
                animations: animationClosure,
                completion: completionClosure
            )
        } else {
            UIView.animate(
                withDuration: animationDuration,
                animations: animationClosure,
                completion: completionClosure
            )
        }
    }

    private var isOnTopPosition: Bool {
        return Int(drawerContainerView.frame.minY) == Int(topPositionY)
    }

    private var isOnMiddlePosition: Bool {
        guard let middlePositionY = middlePositionY else { return false }
        return Int(drawerContainerView.frame.minY) == Int(middlePositionY)
    }

    private var isOnBasePosition: Bool {
        return Int(drawerContainerView.frame.minY) == Int(bottomPositionY)
    }
}
