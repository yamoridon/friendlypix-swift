//
//  KZPropertyMapper+extension.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/10.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import Foundation
import KZPropertyMapper

extension KZPropertyMapper {

    func boxValueAsDate(_ value: NSNumber?) -> NSDate? {
        guard let value = value else {
            return nil
        }
        return NSDate(timeIntervalSince1970: TimeInterval(value.int64Value / 1000))
    }

}
