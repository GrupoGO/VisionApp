//
//  HiddenView.swift
//  VisionApp
//
//  Created by Emilio Cubo Ruiz on 03/09/2019.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

class HiddenView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        Bundle(identifier: "eu.vision-app.VisionApp")!.loadNibNamed("HiddenView", owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(contentView)
    }

    
}
