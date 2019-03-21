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
    var gateway: String = ""
    var ack: String = ""
    var nack: String = ""
    var target: String = ""
    var reply: String = ""
    var rawData: Data = Data()
    
    
    init() {
        self.code = .UNDEF
        self.gateway     = ""
        self.ack = ""
        self.target = ""
        self.reply = ""
        self.rawData = Data()
    }
    
    init(data: Data, code: CommandCode = .UNDEF) {
        self.code = data.commandCode
        self.gateway = data.gateway
        self.rawData = data
        
        
        let commandAck = isCommandAck() ? data.ack(10) : data.ack(18)
        if commandAck == "30" {
            self.ack = commandAck
        } else {
            self.nack = commandAck
        }
        
        self.target = data.taget
        self.reply = data.reply
    }
    
    func evaluateResponse() -> (Bool, String, Int) {
        if self.ack == "30" {
            return (true, "", 0)
        }
        
        switch nack {
        case "31":
            return (false, "Impossibile eseguire il comando in quanto la modalità installazione è disabilitata", 31)
        case "32":
            return (false, "Impossibile eseguire il comando in quanto non valido", 32)
        case "33":
            return (false, "Il Gateway è impegnato nella routine GSM", 33)
        case "34":
            return (false, "Il Gateway non è riuscito a recuperare la propria configurazione", 34)
        case "35":
            return (false, "Impossibile eseguire il comando in quanto l’opzione specificata non valida", 35)
        case "36":
            return (false, "Impossibile eseguire il comando in quanto l’opzione specificata non valida", 36)
        default:
            return (false, "Errore generico", 40)
        }
    }
    
    func isCommandAck() -> Bool {
        let len = rawData.toHexString().count
        let partial = String(rawData.toHexString().substring(with: NSRange(location: 12, length: len - 12 - 4)))
        var isAck = true
        
        partial.split(by: 2).forEach { (hexPart) in
            if hexPart != "03" {
                isAck = false
            }
        }
        
        return isAck
    }

    func getSensorsValues() -> [Int] {
        if isCommandAck() {
            return [Int]()
        }
        
        return rawData.sensorValues
    }
    
    func getDiscoveryNodes() -> [String] {
        let res = rawData.networkNodes
        return res
    }
    
    func getDiscoveryErrorNodes() -> [String] {
        let res = rawData.networkErrorNodes
        return res
    }
    
    
    func getNodeType() -> TipoNodo? {
        let type = rawData.nodeType
        if type.count > 0 {
            return TipoNodo(rawValue: type)
        }
        
        return nil
    }
    
    func getNetworkList() -> [String] {
        let networks = rawData.networks
        return networks
    }
    
    func needCommandDOptionW() -> Bool {
        if rawData.needOptionW {
            return true
        }
        
        return false
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code.rawValue)
        hasher.combine(gateway)
        hasher.combine(ack)
        hasher.combine(target)
        hasher.combine(reply)
    }
    
    static func ==(lhs: CommandResponse, rhs: CommandResponse) -> Bool {
        return lhs.code == rhs.code &&
               lhs.gateway == rhs.gateway &&
               lhs.ack == rhs.ack
    }
    
    var description: String {
        return code.description
    }
}
