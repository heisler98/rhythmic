//Copyright © 2018 Inloop, s.r.o. All rights reserved.

import UIKit

extension UIView {
    func pinSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        let views = ["v": subview]
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|", metrics: nil, views: views)
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|", metrics: nil, views: views)
        NSLayoutConstraint.activate(vertical + horizontal)
    }
}
