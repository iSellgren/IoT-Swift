//
//  File.swift
//  
//
//  Created by Fredrik Sellgren on 2021-12-11.
//

import Foundation
class MQTTPublishMessage{
    func getMessageType(header: UInt8) -> Int
    {
        let firstByte: Int = Int(header)
        let mask = 0b11110000
        let shift = 4
        return (Int(firstByte) & mask) >> shift
        
    }
    func getReserved(header: UInt8) -> Int{
        let firstByte: Int = Int(header)
        let mask = 0b00001111
        let shift = 0
        return (Int(firstByte) & mask) >> shift
        
    }
    func getDUP(header: UInt8) -> Int
    {
        let firstByte: Int = Int(header)
        let mask = 0b00001000
        let shift = 3
        return (Int(firstByte) & mask) >> shift
        
    }
    func getQoS(header: UInt8) -> Int
    {
        let byte: Int = Int(header)
        let mask = 0b00000110
        let shift = 1
        return (Int(byte) & mask) >> shift
    }
    func getRetain(header: UInt8) -> Int
    {
        let byte: Int = Int(header)
        let mask = 0b00000001
        let shift = 0
        return (Int(byte) & mask) >> shift
    }
    func getTopicLen(buffer:UnsafeMutablePointer<UInt8>) ->Int
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    func getTopic(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
        let length = getTopicLen(buffer: buffer)
        var j = 2
        var protocolName:String = ""
        while(j < 2 + length){
            protocolName += String(format:"%c", (Int(buffer[j])))

            j+=1
        }
        print(j)
        return protocolName
    }
    func getMessage(buffer:UnsafeMutablePointer<UInt8>, length: UInt32) -> String
    {
        print("PublishMessage")
        let msglength = Int(length)
        let topiclength = getTopicLen(buffer: buffer)
        
        var j = 2 + topiclength
        var protocolName:String = ""
        while(j < (msglength)){
            protocolName += String(format:"%c", (Int(buffer[j])))

            j+=1
        }
        return protocolName
    }
    
}
