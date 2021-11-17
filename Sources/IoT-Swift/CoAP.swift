//
//  File.swift
//  
//
//  Created by Fredrik Sellgren on 2021-11-12.
//

import Foundation

// Client form:
// In this case, we're connecting to a specific server, so the client will
// usually use:
//       Connect(address)    // Connect to a UDP server
//       Read/Write          // Reads/Writes all go to a single destination
//

class CoAP {
    let port:UInt16 = 5683
    let host:String = "coap.me"
    
    func htons(value: CUnsignedShort) -> CUnsignedShort {
      return (value << 8) + (value >> 8);
    }
    var addressBuffer = [UInt8](repeating:0, count:1024)
    
    func start (){
    
        var addrInfoPointer = UnsafeMutablePointer<addrinfo>(nil)
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_flags |= AI_CANONNAME;

        let resultFromAddrInfo: Int32
        resultFromAddrInfo = getaddrinfo(host, String(port), nil, &addrInfoPointer)
        
        print(resultFromAddrInfo)
        let strLen = Int(INET_ADDRSTRLEN)
        var str = [CChar](repeating: 0, count: strLen)
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: str.count)
        buffer.initialize(from: &str, count: str.count)
        
        if addrInfoPointer!.pointee.ai_family == Int32(AF_INET) {
            var addr = sockaddr_in()
            memcpy(&addr, addrInfoPointer!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in>.size))
            inet_ntop(AF_INET, &addr.sin_addr , buffer, socklen_t(INET_ADDRSTRLEN));
            print(buffer);
        }
        var socketaddr = sockaddr_in()
        socketaddr.sin_len = UInt8(MemoryLayout.size(ofValue: socketaddr))
        socketaddr.sin_family = sa_family_t(AF_INET)
        socketaddr.sin_addr.s_addr = inet_addr(buffer)
        
        let socket = socket(addrInfoPointer!.pointee.ai_family, addrInfoPointer!.pointee.ai_socktype, IPPROTO_UDP)
        
        if socket == -1
        {
            print("Error when creating socket")
            return
        }
        let socklenght = socklen_t(MemoryLayout<sockaddr_in>.size)
        let _: () = withUnsafePointer(to: &socketaddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                print($0.pointee.self)
                connect(socket, addrInfoPointer!.pointee.ai_addr, socklenght)
            }
        }
        
        let hexArray:[UInt8] = [UInt8(0x40), UInt8(0x01), UInt8(0x04), UInt8(0xd2), UInt8(0xb4), UInt8(0x74), UInt8(0x65), UInt8(0x73), UInt8(0x74)]
        
        print(hexArray)
        write(socket, hexArray, hexArray.count)
        let bufferSize:Int = 65536;

        let readBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))

        let readResult = read(socket, readBuffer, bufferSize)
        
        print(readBuffer[0])
        
        print(readResult, "readResult")
        
        let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
        reSizeBuffer.initialize(from: readBuffer, count: readResult)
        
        
        print(buffer,"hejbuffer")
        let message = String(cString: readBuffer)
        print(message)
        
        print(getVersion(buffer: reSizeBuffer))
        print(getT(buffer: reSizeBuffer))
        print(getTLK(buffer: reSizeBuffer))
        print(getmessgeID(buffer: reSizeBuffer))
        print(getTokenLenght(buffer: reSizeBuffer)[0])
        print(getOptions(buffer: reSizeBuffer, size:readResult))
        
    }
}

func getVersion(buffer:UnsafeMutablePointer<UInt8>) -> Int
{
    let firstByte: Int = Int(buffer[0])
    let mask = 0b11000000
    let shift = 6
    
    return (Int(firstByte) & mask) >> shift
    
}
func getT(buffer:UnsafeMutablePointer<UInt8>) -> Int
{
    let firstByte: Int = Int(buffer[0])
    let mask = 0b00110000
    let shift = 4
    
    return (Int(firstByte) & mask) >> shift
}
func getTLK(buffer:UnsafeMutablePointer<UInt8>) -> Int
{
    let firstByte: Int = Int(buffer[0])
    let mask = 0b00001111
    let shift = 0
    
    return (Int(firstByte) & mask) >> shift
}
func getCode(buffer:UnsafeMutablePointer<UInt8>) -> Int
{
    let firstByte: Int = Int(buffer[1])
    
    return firstByte
}
func getmessgeID(buffer:UnsafeMutablePointer<UInt8>) -> Int
{
    var value : UInt16 = 0
//    Takes the data from buffer[2] and buffer[3]
    let data = NSData(bytes: buffer + 2, length: 2)
    data.getBytes(&value, length: 2)
    value = UInt16(bigEndian: value)
    return Int(value)
}
func getTokenLenght(buffer:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>
{
    let tokenLenght = UInt8(getTLK(buffer: buffer))
    
    let ByteArray = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(tokenLenght))
    ByteArray.initialize(from: buffer + 4, count: Int(tokenLenght))

    return ByteArray
}

enum Format {
    case opaque
    case string
    case empty
    case uint
}

struct options {

    var delta: Int
    var length: Int
    var value: [UInt8]
}

func getOptions(buffer:UnsafeMutablePointer<UInt8>, size:Int) -> [options]
{
    let tokenLenght = UInt8(getTLK(buffer: buffer))
    
    
    var OptionArray:[options] = []
    var j = (Int(tokenLenght)+4)
    while(j < size){
    
        if (UInt8(buffer[j]) & 0xff) == 0xff{
            return OptionArray
        }
        let delta = Int(buffer[j])
        let deltamask = 0b11110000
        let deltashift = 4
        
        let length = Int(buffer[j])
        let lengthmask = 0b00001111
        j+=1
        
        let optDelta:Int = (Int(delta) & deltamask) >> deltashift
        let Optlength:Int = (Int(length) & lengthmask)
        
        var OptValue:[UInt8] = []
        
        for i in (0..<Optlength)
        {
            let value = Int(buffer[j])
            OptValue.append(UInt8(value))
            j+=1
        }
        
//        if(Optlength == 0){
//            j+=1
//
//        }
        
        let test = options(delta: optDelta, length: Optlength, value: OptValue)
        OptionArray.append(test)
    }
    
    
    return OptionArray
    
}


