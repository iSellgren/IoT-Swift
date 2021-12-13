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
        getaddrinfo(host, String(port), nil, &addrInfoPointer)
        
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
