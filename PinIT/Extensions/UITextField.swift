//
//  Untitled.swift
//  PinIT
//
//  Created by 김지윤 on 6/19/24.
//

import UIKit

extension UITextField {
    func setPadding(left: CGFloat, right: CGFloat) {
        let paddingViewLeft = UIView(frame: CGRect(x: 0, y: 0, width: left, height: self.frame.height))
        self.leftView = paddingViewLeft
        self.leftViewMode = .always
        
        let paddingViewRight = UIView(frame: CGRect(x: 0, y: 0, width: right, height: self.frame.height))
        self.rightView = paddingViewRight
        self.rightViewMode = .always
    }
}
