//
//  File.swift
//  
//
//  Created by Fredrik Sellgren on 2021-12-11.
//

import Foundation
class MQTTConnectMessage{
    func getMessageType(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let firstByte: Int = Int(buffer[0])
        let mask = 0b11110000
        let shift = 4
        return (Int(firstByte) & mask) >> shift
        
    }
    func getReserved(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let firstByte: Int = Int(buffer[0])
        let mask = 0b00001111
        let shift = 0
        return (Int(firstByte) & mask) >> shift

    }
    func getMessageLen(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let secondByte: Int = Int(buffer[1])
        return secondByte
        
    }
    func getProtocolNameLength(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 2, length: 2)
        data.getBytes(&value, length: 2)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    func getProtocolName(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
        let length =  getProtocolNameLength(buffer: buffer)
        var j = 4
        var protocolName:String = ""
        while(j < 4 + length){
            protocolName += String(format:"%c", (Int(buffer[j])))

            j+=1
        }
        return protocolName
    }
    func getVersion(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 4
        let byte: Int = Int(buffer[length])
        return byte
    }
    func getUserNameFlag(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b1000000
        let shift = 7
        return (Int(byte) & mask) >> shift
    }
    func getPasswordFlag(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b01000000
        let shift = 6
        return (Int(byte) & mask) >> shift
    }
    func getWillRetain(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b00100000
        let shift = 5
        return (Int(byte) & mask) >> shift
    }
    func getQoSFlag(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b00011000
        let shift = 3
        return (Int(byte) & mask) >> shift
    }
    
    func getWillFlag(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b00000100
        let shift = 2
        return (Int(byte) & mask) >> shift
    }
    func getCleanSessionFlag(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b00000010
        let shift = 1
        return (Int(byte) & mask) >> shift
    }
    func getReserveFlag(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var length =  getProtocolNameLength(buffer: buffer)
        length += 5
        let byte: Int = Int(buffer[length])
        let mask = 0b00000001
        let shift = 0
        return (Int(byte) & mask) >> shift
    }

    
    func getAlive(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 10, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    
    func getClientIDLength(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 12, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    func getClientID(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
//        var length =  getProtocolNameLength(buffer: buffer)
        let clientLength = getClientIDLength(buffer: buffer)
//        length += clientLength
        var j = 14
        var clientID:String = ""
        while(j < 14 + clientLength+2){
            clientID += String(format:"%c", (Int(buffer[j])))

            j+=1
        }
        print(clientID)
        return clientID
    }
    func getUserNameLength(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let clientLength = getClientIDLength(buffer: buffer)
        
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 14+clientLength+2, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    
    func getClientUserName(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
        var length =  getProtocolNameLength(buffer: buffer)
        let clientLength = getClientIDLength(buffer: buffer)
        
        return "hej"
    }
    
}
