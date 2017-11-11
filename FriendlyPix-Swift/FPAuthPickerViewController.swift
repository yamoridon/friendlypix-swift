//
//  FPAuthPickerViewController.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import FirebaseAuthUI

class FPAuthPickerViewController: FUIAuthPickerViewController {

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, authUI: FUIAuth) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, authUI: authUI)

        let length = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let gradientLayer = GradientLayer()
        gradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: length, height: length)
        view.layer.insertSublayer(gradientLayer, below: view.layer.presentation())
    }

}
