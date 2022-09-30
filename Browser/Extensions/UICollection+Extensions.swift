//
//  UICollection+Extensions.swift
//  Browser
//
//  Created by Oscar Xahil Montano Ayala on 27/09/22.
//

import Foundation
import UIKit

extension UICollectionView {
    func reloadData(completion: @escaping ()->Void) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })
        { _ in completion() }
    }
}
