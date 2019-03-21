//
//  Command.swift
//  IdroController
//
//  Created by Riccardo Paolillo on 20/12/2018.
//  Copyright © 2018 ABLE. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit


public enum CommandCode: String {
    //case Q = "?"
    
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
    case E = "E"
    case F = "F"
    case G = "G"
    case H = "H"
    case I = "I"
    case J = "J"
    case K = "K"
    case L = "L"
    case M = "M"
    case N = "N"
    case O = "O"
    case P = "P"
    case Q = "Q"
    case R = "R"
    case S = "S"
    case T = "T"
    case U = "U"
    case V = "V"
    case X = "X"
    case Y = "Y"
    case Z = "Z"

    case UNDEF = ""

    var asiiHexValue: String {
        get {
            return Character(self.rawValue).asciiHexValue ?? ""
        }
    }
    
    func waitForDelay(callback: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            callback()
        }
    }
    
    var delay: Double {
        get {
            return 2.0
        }
    }
    
    func waitForResponse(_ message: String = "", showWaitTime: Bool = true, label: UILabel? = nil, callback: @escaping () -> ()) {
        if message.count > 0 {
            label?.text = "\(message)"
            if showWaitTime == true {
                label?.text = "\(message)\nAttendi \(waitForResponseTime) secondi..."
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + waitForResponseTime) {
            callback()
        }
    }
    
    var waitForResponseTime: Double {
        get {
            switch self {
            case .A:
                return 2.0
            case .B:
                return 2.0
            case .C:
                return 35.0
            case .D:
                return 8.0
            case .E:
                return 2.0
            case .F:
                return 2.0
            case .G:
                return 2.0
            case .H:
                return 2.0
            case .I:
                return 2.0
            case .J:
                return 2.0
            case .K:
                return 2.0
            case .L:
                return 2.0
            case .M:
                return 90.0
            case .N:
                return 2.0
            case .O:
                return 2.0
            case .P:
                return 2.0
            case .Q:
                return 2.0
            case .R:
                return 2.0
            case .S:
                return 2.0
            case .T:
                return 2.0
            case .U:
                return 2.0
            case .V:
                return 8.0
            case .X:
                return 2.0
            case .Y:
                return 2.0
            case .Z:
                return 2.0
            case .UNDEF:
                return 0.0
            }
        }
    }
    
    var description: String {
        get {
            switch self {
            case .A:
                return ""
            case .B:
                return ""
            case .C:
                return "Lettura dei sensori"
            case .D:
                return "Scansione dei nodi in campo"
            case .E:
                return ""
            case .F:
                return ""
            case .G:
                return ""
            case .H:
                return ""
            case .I:
                return "Abilitazione della modalità installazione"
            case .J:
                return ""
            case .K:
                return ""
            case .L:
               return ""
            case .M:
                return "Verifica della connessione di rete"
            case .N:
                return "Disabilitazione della modalità installazione"
            case .O:
                return "Verifica dello stato del gateway"
            case .P:
                return ""
            case .Q:
                return ""
            case .R:
                return "Lettura della risposta"
            case .S:
                return ""
            case .T:
                return ""
            case .U:
                return "Cambiamento dell'APN di rete"
            case .V:
                return "Tipologia di un nodo"
            case .X:
                return ""
            case .Y:
                return ""
            case .Z:
                return ""
                
            case .UNDEF:
                return "Comando sconosciuto"
            }
        }
    }
}


class Command: Hashable {
    var commandCode: CommandCode = .UNDEF
    var hexMessage: String = ""
    var gateway: String = ""
    var target: String = ""
    var args: String = ""
    var rawData: Data = Data()
    var response: CommandResponse = CommandResponse()
    
    init(code: CommandCode, gateway: String, target: String, payload: String) {
        self.commandCode = code
        self.gateway = gateway
        self.target = target
        self.args = payload
        
        self.hexMessage = "\(code.asiiHexValue)\(gateway)\(target)\(args)"
        self.rawData = hexMessage.hexDecodedData()
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hexMessage)
    }
    
    static func ==(lhs: Command, rhs: Command) -> Bool {
        return lhs.hexMessage == rhs.hexMessage
    }
    
    var description: String {
        return commandCode.description
    }
}


/*
private enum IdroControllerService: String {
    //case idroControllerE188 = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    case ableE189 = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
}

class Command: BlockOperation {
    var tableView: UITableView?
    var indexPath: IndexPath?
    
    var type: CommandType
    var state: CommandState
    var payload: Data?
    var response: Data?
    
    var serviceModel: NodeServiceModel
    var manager: Manager
    var device: Device
    
    var waitingForWriting: Bool
    var writeSemaphore: DispatchGroup
    
    var waitingForReading: Bool
    var readingSemaphore: DispatchGroup
    
    init(type: CommandType, manager: Manager, device: Device) {
        self.type = type
        self.state = .Begin
        self.payload = nil
        self.response = nil
        
        self.writeSemaphore = DispatchGroup()
        self.readingSemaphore = DispatchGroup()
        self.waitingForWriting = false
        self.waitingForReading = false
        
        self.serviceModel = NodeServiceModel()
        self.manager = manager
        self.device = device
    
        super.init()
        
        self.manager.delegate = self
        
        //self.manager.disconnectFromDevice()
        self.manager.connect(with: self.device)
    }
 
    public func setResponse(raw: Any) {
        switch type {
        case .I:
            response = parseReponse_I(raw: raw)
        case .N:
            response = parseReponse_N(raw: raw)
        case .Q:
            response = parseReponse_Q(raw: raw)
        case .O:
            response = parseReponse_O(raw: raw)
            
        default:
            break
        }
    }
    
    private func parseReponse_I(raw: Any) -> Data {
        return Data()
    }
    private func parseReponse_N(raw: Any) -> Data {
        return Data()
    }
    private func parseReponse_Q(raw: Any) -> Data {
        return Data()
    }
    private func parseReponse_O(raw: Any) -> Data {
        return Data()
    }
    
    
    func write(message: String = "") -> Bool {
        return write(data: message.hexDecodedData())
    }
    func write(data: Data = Data()) -> Bool {
        waitingForWriting = true
        
        writeSemaphore.enter()
        device.peripheral.delegate = self
        let result = writeSemaphore.wait(timeout: .now() + 4)
        
        serviceModel.valueCharacteristic4 = data
        serviceModel.writeValue(withUUID: Characteristic.characteristic4.rawValue, response: true)
        
        if result == .success {
            return true
        }
        
        waitingForWriting = false
        return false
    }

    
    func read(from characteristic: Characteristic) -> Data? {
        waitingForReading = true
        
        readingSemaphore.enter()
        device.peripheral.delegate = self
        serviceModel.setNotify(enabled: true, forUUID: characteristic.rawValue)
        let result = readingSemaphore.wait(timeout: .now() + 4)
        
        if result == .success {
            return serviceModel.valueCharacteristic3
        }
        
        return nil
    }
    
    override func main() {
        super.main()
        
        while device.peripheral.state != .connected {
            print("Device state: \(device.peripheral.state.rawValue)")
            
            manager.disconnectFromDevice()
            usleep(400000)
            manager.connect(with: device)
            usleep(400000)
            print("Connetting...")
        }
        
        if device.peripheral.state == .connected {
            print("Write into 3: 4F 6E 02 00 7E")
            serviceModel.valueCharacteristic4 = "4F6E02007E".hexDecodedData()
            serviceModel.writeValue(withUUID: Characteristic.characteristic4.rawValue, response: true)

            serviceModel.setNotify(enabled: true, forUUID: Characteristic.characteristic3.rawValue)
            let res3 = serviceModel.valueCharacteristic3.reduce("") { "\($0)" + "\(Utils.intToHex(Int($1)) ?? "") " }
            print("Read from 3: \(res3)")
        }
        
        state = CommandState.Begin
        print("Inizio Comando O")
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
        sleep(1)
        
        state = CommandState.Waiting
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
            
        if write(data: "4F6E02007E".hexDecodedData()) == true {
            print("Write effettuata con successo")
        } else {
            print("Write fallita")
        }
        
        state = CommandState.Waiting
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
        
        if let data = read(from: Characteristic.characteristic3) {
            let result = data.reduce("") { "\($0)" + "\(Utils.intToHex(Int($1)) ?? "") " }
            print("Read from 3: \(result)")
        } else {
            print("Read fallita")
        }
        
        state = CommandState.Completed
        DispatchQueue.main.async { self.tableView?.reloadSections(IndexSet(integer:0), with: .fade) }
    }
}


extension Command: ManagerDelegate {
    
    func manager(_ manager: Manager, didFindDevice device: Device) {
        
    }
    
    func manager(_ manager: Manager, willConnectToDevice device: Device) {
        device.register(serviceModel: serviceModel)
    }
    
    func manager(_ manager: Manager, connectedToDevice device: Device) {
        device.peripheral.delegate = self
    }
    
    func manager(_ manager: Manager, disconnectedFromDevice device: Device, willRetry retry: Bool) {

    }
}


extension Command: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if waitingForReading == true {
            readingSemaphore.leave()
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if waitingForReading == true {
            readingSemaphore.leave()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if waitingForWriting == true {
            writeSemaphore.leave()
        }
    }
}
*/
