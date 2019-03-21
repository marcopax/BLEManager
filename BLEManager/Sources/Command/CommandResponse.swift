//
//  CommandResponse.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 24/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import Foundation


class CommandResponse: Hashable {
    var code: CommandCode = .UNDEF
    var rawData: Data = Data()

    init(with data: Data = Data(), code: CommandCode = .UNDEF) {
        self.rawData = data
        self.code = code
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code.rawValue)
        hasher.combine(rawData)
    }
    
    static func ==(lhs: CommandResponse, rhs: CommandResponse) -> Bool {
        return lhs.code == rhs.code && lhs.rawData == rhs.rawData
    }
    
    var description: String {
        return code.description
    }
}
