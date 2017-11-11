//
//  FPAppState.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

class FPAppState {

    private init() {
    }

    var currentUser: FPUser?

    static var sharedInstance = FPAppState()
}
