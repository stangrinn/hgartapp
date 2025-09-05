//
//  PaddedLabelText.swift
//  HGArt
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-09-01.
//

import UIKit

class PaddedLabelText: UILabel {
    var padding = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}
