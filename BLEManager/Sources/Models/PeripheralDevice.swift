//
//  PeripheralDevice.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 08/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation


class PeripheralDevice: Equatable, Comparable, Hashable {
    
    var peripheral: CBPeripheral
    var services: [CBService]
    var characteristics: [CBCharacteristic]!
    
    init(with peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.services = peripheral.services ?? [CBService]()
    }
    
    static func ==(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }
    
    static func <(lhs: PeripheralDevice, rhs: PeripheralDevice) -> Bool {
        let lhsName = lhs.peripheral.name ?? "NoName"
        let rhsName = rhs.peripheral.name ?? "NoName"
        
        switch lhsName.compare(rhsName) {
        case .orderedDescending:
            return false
        case .orderedAscending:
            return true
        case .orderedSame:
            return lhs.peripheral.identifier.uuidString > rhs.peripheral.identifier.uuidString
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral.identifier.uuidString)
    }
}

extension Array where Iterator.Element: PeripheralDevice {
    
    @discardableResult
    mutating func appendDistinc(_ device: Iterator.Element ) -> Bool {
        if contains(device) == false {
            append(device)
            return true
        }
        
        return false
    }
}
