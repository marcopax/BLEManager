//
//  BluetoothManager.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 02/01/2019.
//  Copyright © 2019 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit

typealias TimeoutCallback = (()->())
typealias ScanningCallback = (([PeripheralDevice])->())
typealias ConnectCallback = ((PeripheralDevice, Bool)->())
typealias WriteCallback = ((PeripheralDevice, Bool)->())
typealias NotifyCallback = ((PeripheralDevice, CommandResponse, Bool)->())

class BluetoothManager: NSObject {
    
    static var shared: BluetoothManager = BluetoothManager()
    
    private var connectingSemaphore: DispatchGroup
    private var subcribeSemaphore: DispatchGroup
    private var serviceSemaphore: DispatchGroup
    private var characteristicSemaphore: DispatchGroup
    
    private var needLeaveConnecting: Bool
    private var needLeaveSubcribe: Bool
    private var needLeaveService: Bool
    private var needLeaveCharacteristic: Bool
    
    private var manager: CBCentralManager!
    private var eventQueue: DispatchQueue!
    private var parameterMap: [DeviceOperationType: Any]!
    
    var peripherals: [PeripheralDevice]!
    var connectedDevice: PeripheralDevice?
    private var lastConnectedDevice: PeripheralDevice?
    
    private var writeTimeout: Timer?
    private var writeTimeoutCallback: TimeoutCallback?
    
    private var scanningCallback: ScanningCallback?
    private var connectCallback: ConnectCallback?
    private var writeCallback: WriteCallback?
    private var notifyCallback: NotifyCallback?
    
    @objc dynamic var isConnected: Bool {
        get {
            if let connected = connectedDevice {
                return connected.peripheral.state == .connected
            }
            
            return false
        }
        set (newValue) {
            if newValue == false {
                connectedDevice = nil
            }
        }
    }
    
    private override init() {
        connectingSemaphore = DispatchGroup()
        serviceSemaphore = DispatchGroup()
        characteristicSemaphore = DispatchGroup()
        subcribeSemaphore = DispatchGroup()
        
        needLeaveConnecting = false
        needLeaveService = false
        needLeaveCharacteristic = false
        needLeaveSubcribe = false
        
        parameterMap = [DeviceOperationType: Any]()
        
        peripherals = [PeripheralDevice]()
        eventQueue = DispatchQueue(label: "it.idrocontroller.ble.event.queue")
        
        writeTimeout = nil
        writeTimeoutCallback = nil
        
        scanningCallback = nil
        connectCallback = nil
        writeCallback = nil
        notifyCallback = nil
        
        super.init()
        manager = CBCentralManager(delegate: self, queue: eventQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    private func startWriteTimeoutTimer(_ timeout: Double = 4.0) {
        TimeoutTimer.invalidate(timer: writeTimeout)
        
        writeTimeout = TimeoutTimer.detachTimer(relative: timeout) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.writeTimeoutCallback?()
        }
    }



    func scanForPeripheral(_ prefix: String? = nil, completion: @escaping ScanningCallback) {
        parameterMap[.Scanning] = prefix
        scanningCallback = completion
        peripherals = [PeripheralDevice]()
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    @discardableResult
    func connect(to device: PeripheralDevice) -> Bool {
        parameterMap[.Connect] = device.peripheral.name
        
        if device.peripheral.state != .connected {
            connectingSemaphore.enter()
            needLeaveConnecting = true
            manager.connect(device.peripheral, options: nil)

            if connectingSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
                return false
            }
        }
        
        connectedDevice = device
        lastConnectedDevice = connectedDevice
        
        return discoverServicesForConnectedDevice()
    }

    @discardableResult
    func reconnect() -> Bool {
        if let device = lastConnectedDevice {
            isConnected = connect(to: device)
        } else {
            isConnected = false
        }
        
        return isConnected
    }
    
    @discardableResult
    private func discoverServicesForConnectedDevice() -> Bool {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Service] = peripheral.name
            
            serviceSemaphore.enter()
            needLeaveService = true
            
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            if serviceSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
                return false
            }
            
            //Saving discovered services
            connectedDevice?.services = peripheral.services ?? [CBService]()
            
            var result: Bool = true
            peripheral.services?.forEach{ (service) in
                let res = discoverCharacteristicsForConnectedDevice(for: service)
                if res == true {
                    //Saving discovered characteristics
                    if connectedDevice?.characteristics == nil {
                        connectedDevice?.characteristics = [CBCharacteristic]()
                    }
                    
                    connectedDevice?.characteristics.append(contentsOf: service.characteristics ?? [CBCharacteristic]())
                }
                
                result = result && res
            }
            
            return result
        }
        
        return false
    }
    
    @discardableResult
    private func discoverCharacteristicsForConnectedDevice(for service: CBService) -> Bool {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Characteristic] = peripheral.name
            
            characteristicSemaphore.enter()
            needLeaveCharacteristic = true
            peripheral.delegate = self
            peripheral.discoverCharacteristics(nil, for: service)
            if characteristicSemaphore.wait(timeout: .now() + 4) == DispatchTimeoutResult.timedOut {
                return false
            }
            
            return true
        }
        
        return false
    }
    
    /*
    func readData(from characteristic: Characteristic, completion: @escaping NotifyCallback) {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Read] = peripheral.name
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic.rawValue}) {
                notifyCallback = completion
                peripheral.readValue(for: cbcharacteristic)
            }
        }
    }
    */
    
    func subscribe(to characteristic: Characteristic, completion: @escaping NotifyCallback) {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Subscribe] = peripheral.name
            parameterMap[.Read] = peripheral.name
            
            notifyCallback = completion
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic.rawValue}) {
                if cbcharacteristic.isNotifying {
                    peripheral.readValue(for: cbcharacteristic)
                    return
                }
                
                subcribeSemaphore.enter()
                needLeaveSubcribe = true
                peripheral.setNotifyValue(true, for: cbcharacteristic)
                subcribeSemaphore.wait()
        
                peripheral.readValue(for: cbcharacteristic)
            }
        }
    }
    
    func unsubscribe(to characteristic: Characteristic) {
        if let peripheral = connectedDevice?.peripheral {
            parameterMap[.Subscribe] = peripheral.name
            
            if let cbcharacteristic = connectedDevice?.characteristics.first(where: {$0.uuid.uuidString == characteristic.rawValue}) {
                if cbcharacteristic.isNotifying {
                    return
                }
                
                subcribeSemaphore.enter()
                needLeaveSubcribe = true
                peripheral.setNotifyValue(false, for: cbcharacteristic)
                subcribeSemaphore.wait()
            }
        }
    }

    func write(command: Command, to characteristic: Characteristic, modality: CBCharacteristicWriteType = .withResponse, writeTimeout: @escaping TimeoutCallback, completion: @escaping WriteCallback) {
        if let device = connectedDevice {
            parameterMap[.Write] = device.peripheral.name
            
            let data = command.hexMessage.hexDecodedData()
            
            if let cbcharacteristic = device.characteristics.first(where: {$0.uuid.uuidString == characteristic.rawValue}) {
                if modality == .withResponse {
                    print("Writing \(data.toHexString()) to characteristic: \(cbcharacteristic.uuid.uuidString)...")
                    writeCallback = completion
                    writeTimeoutCallback = writeTimeout
                    command.commandCode.waitForDelay {
                        self.startWriteTimeoutTimer()
                        device.peripheral.writeValue(data, for: cbcharacteristic, type: .withResponse)
                    }
                }
                else {
                    command.commandCode.waitForDelay {
                        device.peripheral.writeValue(data, for: cbcharacteristic, type: .withoutResponse)
                        completion(device, true)
                    }
                }
            }
        }
    }
    
    func registerConnnectionObserver(_ callback: @escaping ((Bool) -> ())) -> NSKeyValueObservation {
        let observer = self.observe(\.isConnected, options: [.old, .new]) { (object, change) in
            callback(self.isConnected)
        }
        
        return observer
    }
    
    func disconnect() {
        if let peripheral = connectedDevice?.peripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
    }

    func stopScan() {
        manager.stopScan()
    }
}


extension BluetoothManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        case .unsupported:
            print("Unsupported")
        case .unauthorized:
            print("Unauthorized")

        case .poweredOff:
            print("PowerOff")
        case .poweredOn:
            print("PowerOn")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Found Peripheral: \(peripheral.name ?? "No Nome")")
        
        let prefix = parameterMap[.Scanning] as? String ?? ""
        let name = peripheral.name ?? ""
        if name.count == 0 || prefix.count > 0 {
            if name.contains(prefix) == false && name.contains("IdroCtrl") == false {
                return
            }
        }
        
        let needRefresh = peripherals.appendDistinc(PeripheralDevice(with: peripheral))
        peripherals = peripherals.sorted()
        
        if needRefresh {
            DispatchQueue.main.async {
                self.scanningCallback?(self.peripherals)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let name = parameterMap[.Connect] as? String, name == peripheral.name {
            isConnected = true
            
            if needLeaveConnecting == true {
                needLeaveConnecting = false
                connectingSemaphore.leave()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let name = parameterMap[.Service] as? String, name == peripheral.name {
            if needLeaveService == true {
                needLeaveService = false
                serviceSemaphore.leave()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let name = parameterMap[.Characteristic] as? String, name == peripheral.name {
            if needLeaveCharacteristic == true {
                needLeaveCharacteristic = false
                characteristicSemaphore.leave()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Update Value with value: \(characteristic.value?.toHexString() ?? "")")
            
        if let connectedDev = connectedDevice, let data = characteristic.value {
            DispatchQueue.main.async {
                let response = CommandResponse(with: data)
                self.notifyCallback?(connectedDev, response, (error == nil))
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let connectedDev = connectedDevice {
            DispatchQueue.main.async {
                TimeoutTimer.invalidate(timer: self.writeTimeout)
                self.writeCallback?(connectedDev, (error == nil))
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if needLeaveSubcribe == true {
            needLeaveSubcribe = false
            subcribeSemaphore.leave()
        }
    }
    
}
