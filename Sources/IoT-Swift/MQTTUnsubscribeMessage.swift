//
//  File.swift
//  
//
//  Created by Fredrik Sellgren on 2021-12-11.
//

import Foundation
class MQTTUnsubscribeMessage{
    func getMessageType(buffer:UnsafeMutablePointer<UInt8>) -> Int{
        let firstByte: Int = Int(buffer[0])
        let mask = 0b11110000
        let shift = 4
        return (Int(firstByte) & mask) >> shift
        
    }
    func getReserved(buffer:UnsafeMutablePointer<UInt8>) -> Int{
        let firstByte: Int = Int(buffer[0])
        let mask = 0b00001111
        let shift = 0
        return (Int(firstByte) & mask) >> shift
        
    }
    func getMsgLen(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let secondByte: Int = Int(buffer[1])
        return secondByte
    }
    func getMsgIdentifier(buffer:UnsafeMutablePointer<UInt8>) -> (UInt8,UInt8)
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 2, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        var MessageIDFirst:UInt8 = 0
        var MessageIDSecond:UInt8 = 0
        
        MessageIDFirst = UInt8((value >> 8) & 0xFF)
        MessageIDSecond = UInt8((value & 0xFF))
        print(MessageIDFirst,MessageIDSecond)
        return (MessageIDFirst, MessageIDSecond)
    }
    func getTopicLength(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 4, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    func getTopic(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
        let length = getTopicLength(buffer: buffer)
        var j = 6
        var protocolName:String = ""
        while(j < 6 + length){
            protocolName += String(format:"%c", (Int(buffer[j])))
            j+=1
        }
        return protocolName
    }
    func getReservedQoS(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let topicLength = getTopicLength(buffer: buffer)
        let ReqQoS: Int = Int(buffer[topicLength+6])
        let mask = 0b11111100
        let shift = 2
        return (Int(ReqQoS) & mask) >> shift
    }
    func getRequestedQoS(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let topicLength = getTopicLength(buffer: buffer)
        let ReqQoS: Int = Int(buffer[topicLength+6])
        let mask = 0b00000011
        let shift = 0
        return (Int(ReqQoS) & mask) >> shift
    }
    
    
}
