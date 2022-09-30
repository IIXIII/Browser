//
//  UIView+Extensions.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 26/09/22.
//

import Foundation
import UIKit

extension UIView {
    func constraintsEquals(to viewAttached: UIView? = nil) {
        guard let superview = viewAttached ?? superview else { return }
        translatesAutoresizingMaskIntoConstraints = false        
        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }
    
    func constraintsCenter() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }
    
    public func removeAllConstraints() {
        var _superview = superview
        
        while let superview = _superview {
            for constraint in superview.constraints {
                
                if let first = constraint.firstItem as? UIView, first == self {
                    superview.removeConstraint(constraint)
                }
                
                if let second = constraint.secondItem as? UIView, second == self {
                    superview.removeConstraint(constraint)
                }
            }
            
            _superview = superview.superview
        }
        
        removeConstraints(constraints)
        translatesAutoresizingMaskIntoConstraints = true
    }
}
