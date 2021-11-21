//
//  CoAPConnection.swift
//  
//
//  Created by Fredrik Sellgren on 2021-11-20.
//

import Foundation

class CoAPConnection {
    let port:UInt16 = 5683
    let host:String = "coap.me"
    
    func startConnection() -> Int32{
        var addrInfoPointer = UnsafeMutablePointer<addrinfo>(nil)
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_flags |= AI_CANONNAME;

        let _:Int32 = getaddrinfo(host, String(port), nil, &addrInfoPointer)
        
        let strLen = Int(INET_ADDRSTRLEN)
        var str = [CChar](repeating: 0, count: strLen)
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: str.count)
        buffer.initialize(from: &str, count: str.count)
        
        if addrInfoPointer!.pointee.ai_family == Int32(AF_INET) {
            var addr = sockaddr_in()
            memcpy(&addr, addrInfoPointer!.pointee.ai_addr, Int(MemoryLayout<sockaddr_in>.size))
            inet_ntop(AF_INET, &addr.sin_addr , buffer, socklen_t(INET_ADDRSTRLEN));
        }
        var socketaddr = sockaddr_in()
        socketaddr.sin_len = UInt8(MemoryLayout.size(ofValue: socketaddr))
        socketaddr.sin_family = sa_family_t(AF_INET)
        socketaddr.sin_addr.s_addr = inet_addr(buffer)
        
        let socket = socket(addrInfoPointer!.pointee.ai_family, addrInfoPointer!.pointee.ai_socktype, IPPROTO_UDP)
        
        if socket == -1
        {
            print("Error when creating socket")
            return -1
        }
        let socklenght = socklen_t(MemoryLayout<sockaddr_in>.size)
                connect(socket, addrInfoPointer!.pointee.ai_addr, socklenght)
        return socket
    }
    
}
