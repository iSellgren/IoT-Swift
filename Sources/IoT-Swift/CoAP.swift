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
        send(socket, hexArray, 9,0)
        
    }
}
