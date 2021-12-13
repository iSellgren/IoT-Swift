//
//  File.swift
//  
//
//  Created by Fredrik Sellgren on 2021-12-11.
//

import Foundation
class MQTTPublishMessage{
    func getMessageType(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
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
    func getDUP(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let firstByte: Int = Int(buffer[0])
        let mask = 0b00001000
        let shift = 3
        return (Int(firstByte) & mask) >> shift
        
    }
    func getQoS(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let byte: Int = Int(buffer[0])
        let mask = 0b00000110
        let shift = 1
        return (Int(byte) & mask) >> shift
    }
    func getRetain(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let byte: Int = Int(buffer[0])
        let mask = 0b00000001
        let shift = 0
        return (Int(byte) & mask) >> shift
    }
    func getMsgLen(buffer:UnsafeMutablePointer<UInt8>) -> Int
    {
        let secondByte: Int = Int(buffer[1])
        return secondByte
    }
    func getTopicLen(buffer:UnsafeMutablePointer<UInt8>) ->Int
    {
        var value : UInt16 = 0
        let data = NSData(bytes: buffer + 2, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt16(bigEndian: value)
        return Int(value)
    }
    func getTopic(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
        let length = getTopicLen(buffer: buffer)
        var j = 4
        var protocolName:String = ""
        while(j < 4 + length){
            protocolName += String(format:"%c", (Int(buffer[j])))

            j+=1
        }
        print(j)
        return protocolName
    }
    func getMessage(buffer:UnsafeMutablePointer<UInt8>) -> String
    {
        print("PublishMessage")
        let msglength = getMsgLen(buffer: buffer)
        let topiclength = getTopicLen(buffer: buffer)
        
        var j = 4 + topiclength
        var protocolName:String = ""
        while(j < (2+msglength)){
            protocolName += String(format:"%c", (Int(buffer[j])))

            j+=1
        }
        return protocolName
    }
    
}
