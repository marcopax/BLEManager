//
//  Data+Parser.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 25/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


extension Data {
    var isZeroFilled: Bool {
        get {
            return toHexString().filter({ $0 != "0"}).count == 0
        }
    }
}
