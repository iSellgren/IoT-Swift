//
//  Server.swift
//  IoT-protocols
//
//  Created by Fredrik Sellgren on 2021-11-03.
//

import Foundation

var subFilters: [String:Array<Int32>] = [:]
class PingResponse{
    let responseMessage:[UInt8] = [(0xD0), (0x00)]
    
    func sendPingResponse(client:Int32, buffer:UnsafeMutablePointer<UInt8>){
        
        let connectMessage = MQTTConnectMessage.init()
        let messageType = connectMessage.getMessageType(buffer: buffer)
        if(messageType == 12){
            send(client, responseMessage, responseMessage.capacity,0)
        }
    }
}
class DisconnectMessage{
    let disconnectMessage:[UInt8] = [(0xE0), (0x00)]
    func sendDisconnectAck(client:Int32, buffer:UnsafeMutablePointer<UInt8>){
        
        let connectMessage = MQTTConnectMessage.init()
        let messageType = connectMessage.getMessageType(buffer: buffer)
        if(messageType == 14){
            close(client)
        }
    }
}

class PublishMessage{
    
    func sendpublishAck(client:Int32, buffer:UnsafeMutablePointer<UInt8>){
        
        let publishMessage = MQTTPublishMessage.init()
        let messageType = publishMessage.getMessageType(buffer: buffer)

        if(messageType == 3)
        {
            let DUP = publishMessage.getDUP(buffer: buffer)
            let QoS = publishMessage.getQoS(buffer: buffer)
            let Retain = publishMessage.getRetain(buffer:buffer)
            let msgLen = publishMessage.getMsgLen(buffer:buffer)
            let topiclen = publishMessage.getTopicLen(buffer:buffer)
            let topic = publishMessage.getTopic(buffer:buffer)
            let message = publishMessage.getMessage(buffer:buffer)
            let bufferlength:Int = Int(MemoryLayout.size(ofValue: buffer).self)
            let data = NSData(bytesNoCopy: buffer, length: msgLen+2, freeWhenDone: false)
            let array = [UInt8](data)
            
            if(QoS == 0)
            {
                sendToAllInDict(client: client, topic: array, topiclength: msgLen+2, subFilters: subFilters)

            }
            if(QoS == 1)
            {
                let Message:[UInt8] = [(0x40), (0x02),(0x00), (0x01)]
                send(client, Message, Message.capacity,0)
                sendToAllInDict(client: client, topic: array, topiclength: msgLen+2, subFilters: subFilters)
            }
            if(QoS == 2)
            {
                let Message:[UInt8] = [(0x50), (0x02),(0x00), (0x01)]
                send(client, Message, Message.capacity,0)
                let msgLen = publishMessage.getMsgLen(buffer:buffer)
                let data = NSData(bytesNoCopy: buffer, length: msgLen+2, freeWhenDone: false)
                let array = [UInt8](data)
            }
        }
        
        else if (messageType == 6){
            if(publishMessage.getReserved(buffer: buffer) != 2){
                print("Bits 3,2,1,0 is wrong closing connection PUBLISH")
                DisconnectMessage.init().sendDisconnectAck(client: client, buffer: buffer)
                
            }

            let Message:[UInt8] = [(0x70), (0x02),(0x00), (0x01)]
            send(client, Message, Message.capacity,0)
//            sendToAllInDict(client: client, topic: array, topiclength: msgLen+2, subFilters: subFilters)
        }
    }
}


class UnsubscribeMessage{
    func getUnsubscribeMessage(client:Int32, buffer:UnsafeMutablePointer<UInt8>){
        let unsubscribeMessage = MQTTUnsubscribeMessage.init()
        let messageType = unsubscribeMessage.getMessageType(buffer: buffer)
        
        if(messageType == 10){
            if(unsubscribeMessage.getReservedQoS(buffer: buffer) != 0){
                print("Bits 3,2,1,0 is wrong closing connection SUBSCRIBE")
                DisconnectMessage.init().sendDisconnectAck(client: client, buffer: buffer)
            }
            
            let MessageID = unsubscribeMessage.getMsgIdentifier(buffer: buffer)
            let firstMessageID = MessageID.0
            let secondMessageID = MessageID.1
            let UnSubAck:[UInt8] = [(0xB0), (0x02), (firstMessageID), (secondMessageID)]
            
            let getTopic = unsubscribeMessage.getTopic(buffer: buffer)
            popDict(client: client, getTopic: getTopic, subFilters: &subFilters)
            print(subFilters)
            send(client, UnSubAck, UnSubAck.capacity,0)
        }
    }
}

class SubscribeMessage{
    
    func getSubscribeMessage(client:Int32, buffer:UnsafeMutablePointer<UInt8>){
        let subscribeMessage = MQTTSubscribeMessage.init()
        let messageType = subscribeMessage.getMessageType(buffer: buffer)
        
        if(messageType == 8)
        {
            if(subscribeMessage.getReservedQoS(buffer: buffer) != 0){
                print("Bits 3,2,1,0 is wrong closing connection SUBSCRIBE")
                DisconnectMessage.init().sendDisconnectAck(client: client, buffer: buffer)
            }
            let MessageID = subscribeMessage.getMsgIdentifier(buffer: buffer)
            let firstMessageID = MessageID.0
            let secondMessageID = MessageID.1
            let SuBackQoS0:[UInt8] = [(0x90), (0x03), (firstMessageID), (secondMessageID),(0x00)]
            let SuBackQoS1:[UInt8] = [(0x90), (0x03), (firstMessageID), (secondMessageID), (0x01)]
            let SuBackQoS2:[UInt8] = [(0x90), (0x03), (firstMessageID), (secondMessageID),(0x02)]
            let Failure:[UInt8] = [(0x90), (0x03), (firstMessageID), (secondMessageID), (0x80)]
            
            if(subscribeMessage.getRequestedQoS(buffer: buffer) == 0){
                let getTopic = subscribeMessage.getTopic(buffer: buffer)
                setDict(client: client, getTopic: getTopic, subFilters: &subFilters)
                print(subFilters)
                send(client, SuBackQoS0, SuBackQoS0.capacity,0)
            }else if(subscribeMessage.getRequestedQoS(buffer: buffer) == 1){
                let getTopic = subscribeMessage.getTopic(buffer: buffer)
                setDict(client: client, getTopic: getTopic, subFilters: &subFilters)
                send(client, SuBackQoS1, SuBackQoS1.capacity,0)
            }else if(subscribeMessage.getRequestedQoS(buffer: buffer) == 2){
                let getTopic = subscribeMessage.getTopic(buffer: buffer)
                setDict(client: client, getTopic: getTopic, subFilters: &subFilters)
                send(client, SuBackQoS2, SuBackQoS2.capacity,0)
            }else{
                send(client, Failure, Failure.capacity,0)
            }
        }
    }
}
func sendToAllInDict(client: Int32, topic: [UInt8], topiclength: Int, subFilters: [String:Array<Int32>]){
    print("-------")
    for (filter,value) in subFilters{
        for i in value{
            print(i)
            print(topic)
            print(topiclength)
            send(i,topic,topiclength,0)
        }

    }
}

func setDict(client: Int32, getTopic: String, subFilters:inout [String:Array<Int32>]){
    if(subFilters[getTopic] == nil){
        subFilters[getTopic] = []
    }
    subFilters[getTopic]?.append(client)
}
func popDict(client: Int32, getTopic: String, subFilters:inout [String:Array<Int32>]){
    subFilters = subFilters.mapValues{ $0.filter{ $0 != client } }
}

class ConnectAckMessage{
    let connAccepted:[UInt8] = [(0x20), (0x02), (0x00), (0x00)]
    let protocolVerWrong:[UInt8] = [(0x20), (0x02), (0x00), (0x01)]
    let idRejected:[UInt8] = [(0x20), (0x02), (0x00), (0x02)]
    let serverUnavailble:[UInt8] = [(0x20), (0x02), (0x00), (0x03)]
    let badUsernameOrPassword:[UInt8] = [(0x20), (0x02), (0x00), (0x04)]
    let notauthorized:[UInt8] = [(0x20), (0x02), (0x00), (0x05)]
    
    func sendConnectAck(client:Int32, buffer:UnsafeMutablePointer<UInt8>){
        
        let connectMessage = MQTTConnectMessage.init()
        let messageType = connectMessage.getMessageType(buffer: buffer)

        
        if(messageType == 1){
            let messageLen = connectMessage.getMessageLen(buffer: buffer)
            let protocolName = connectMessage.getProtocolName(buffer: buffer)
            let protocolNameLen = connectMessage.getProtocolNameLength(buffer: buffer)
            let version = connectMessage.getVersion(buffer: buffer)
            let clientIDLength = connectMessage.getClientIDLength(buffer: buffer)
            let clientName = connectMessage.getClientID(buffer: buffer)
            print(connectMessage.getClientUserName(buffer: buffer))
            if (version != 4 && messageType == 1)
            {
                print(protocolVerWrong)
                send(client, protocolVerWrong, protocolVerWrong.capacity,0)
            }
            else if(messageType == 1 && protocolNameLen == 4 && protocolName == "MQTT" && version == 4){
                print(connAccepted)
                send(client, connAccepted, connAccepted.capacity,0)
            }
            
        }

    }
}


class MQTT {
    
    func start (){
//        Creating the socket

        
        let serverPort = String(1883)
        let socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)

        if socket == -1
        {
            close(socket)
            print("Error when creating socket")
            return
        }
        var use_opt:Int32 = 0
        let sizeOfUseOpT:UInt32 = UInt32(MemoryLayout.size(ofValue: use_opt).self)
        
        if (setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &use_opt, sizeOfUseOpT) != 0){
            close(socket)
            print("Fail to get socketPort")
        }
        
        var identifyHost = addrinfo(ai_flags: AI_PASSIVE, ai_family: AF_INET, ai_socktype: SOCK_STREAM, ai_protocol: 0, ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil)
        
        var addrInfoPointer: UnsafeMutablePointer<addrinfo>? = nil
        
        let resultFromAddrInfo: Int32
        
        resultFromAddrInfo = getaddrinfo(nil, serverPort, &identifyHost, &addrInfoPointer)
        print(resultFromAddrInfo)
        if resultFromAddrInfo != 0 {
            close(socket)
            print("Error getting information from address ErrorCode: \(errno)")
        }

        let binding: Int32
        binding = bind(socket, addrInfoPointer!.pointee.ai_addr, socklen_t(addrInfoPointer!.pointee.ai_addrlen))
        
        if binding == -1
        {
            freeaddrinfo(addrInfoPointer)
            close(socket)
            print("Error binding socket to address ErrorCode: \(errno)")
            return
        }
        
        freeaddrinfo(addrInfoPointer)

        let maxNumberOfConnections: Int32 = 10
        let listenToSocket:Int32 = listen(socket, maxNumberOfConnections)

        if listenToSocket == -1
        {
            close(socket)
            print("Error: Cant lisen to socket ErrorCode: \(errno)")
            return
        }
        
        let connectionQueue = DispatchQueue(label: "ConnectionQueue", attributes: [.concurrent])
        acceptClientConnections: while true {
            
            var socketAdress:sockaddr = sockaddr()
            var socketAdressLength:UInt32 = UInt32(MemoryLayout.size(ofValue: socketAdress).self)
            
            let client = accept(socket, &socketAdress, &socketAdressLength)

            let (ipAddress, servicePort) = sockaddrDescription(addr: &socketAdress)
            
//            let message = "Accepted connection from: " + (ipAddress ?? "nil") + ", from port:" + (servicePort ?? "nil")
            print(client)
            
            connectionQueue.async() {
                receiveAndDispatch(client: client)
                
            }
        }
    }
}
func receiveAndDispatch(client: Int32) {

    let dataProcessingQueue = DispatchQueue(label: "dataProcessingQueue", attributes: [.concurrent] )
    let bufferSize = 256
    let readBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))
    
    reciveDataFromClients: while true {
        
        let numOfFd:Int32 = client + 1
        var readSet:fd_set = fd_set(fds_bits: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        
        fdSet(client, set: &readSet)
        let status = select(numOfFd, &readSet, nil, nil,nil)
        
        let readResult = recv(client,readBuffer,bufferSize,0)
        print("hedsadsa")
        print(readResult)
        
        if readResult == -1 {
            
            let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
            reSizeBuffer.initialize(from: readBuffer, count: readResult)
            DisconnectMessage.init().sendDisconnectAck(client: client, buffer: reSizeBuffer)
            break reciveDataFromClients
        }
        if readResult == 0 {
            print("0")
            let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
            reSizeBuffer.initialize(from: readBuffer, count: readResult)
            DisconnectMessage.init().sendDisconnectAck(client: client, buffer: reSizeBuffer)
            break reciveDataFromClients
        }
        
        let message = "Received \(readResult) bytes from the client \(client)"
        print(message)
        
        let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
        reSizeBuffer.initialize(from: readBuffer, count: readResult)
        let bufferlength:Int = Int(MemoryLayout.size(ofValue: reSizeBuffer).self)
        dataProcessingQueue.async() {
            processClientData(client: client, data: reSizeBuffer, size: readResult)
            
        }
    }
}
func processClientData(client: Int32,data: UnsafeMutablePointer<UInt8>, size:Int) {
    print("insideProcessData")
    ConnectAckMessage.init().sendConnectAck(client: client, buffer: data)
    SubscribeMessage.init().getSubscribeMessage(client: client, buffer: data)
    UnsubscribeMessage.init().getUnsubscribeMessage(client: client, buffer: data)
    PublishMessage.init().sendpublishAck(client: client, buffer: data)
    PingResponse.init().sendPingResponse(client: client, buffer: data)
}
func sockaddrDescription(addr: UnsafePointer<sockaddr>) -> (String?, String?) {
    
    var host : String?
    var service : String?
    
    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    var serviceBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))
    
    if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostBuffer, socklen_t(hostBuffer.count), &serviceBuffer, socklen_t(serviceBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV) == 0 {
        
        host = String(cString: hostBuffer)
        service = String(cString: serviceBuffer)
    }
    return (host, service)
}

func fdSet(_ fd: Int32, set: inout fd_set) {
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask:Int32 = 1 << bitOffset
    switch intOffset {
        case 0: set.fds_bits.0 = set.fds_bits.0 | mask
        case 1: set.fds_bits.1 = set.fds_bits.1 | mask
        case 2: set.fds_bits.2 = set.fds_bits.2 | mask
        case 3: set.fds_bits.3 = set.fds_bits.3 | mask
        case 4: set.fds_bits.4 = set.fds_bits.4 | mask
        case 5: set.fds_bits.5 = set.fds_bits.5 | mask
        case 6: set.fds_bits.6 = set.fds_bits.6 | mask
        case 7: set.fds_bits.7 = set.fds_bits.7 | mask
        case 8: set.fds_bits.8 = set.fds_bits.8 | mask
        case 9: set.fds_bits.9 = set.fds_bits.9 | mask
        case 10: set.fds_bits.10 = set.fds_bits.10 | mask
        case 11: set.fds_bits.11 = set.fds_bits.11 | mask
        case 12: set.fds_bits.12 = set.fds_bits.12 | mask
        case 13: set.fds_bits.13 = set.fds_bits.13 | mask
        case 14: set.fds_bits.14 = set.fds_bits.14 | mask
        case 15: set.fds_bits.15 = set.fds_bits.15 | mask
        case 16: set.fds_bits.16 = set.fds_bits.16 | mask
        case 17: set.fds_bits.17 = set.fds_bits.17 | mask
        case 18: set.fds_bits.18 = set.fds_bits.18 | mask
        case 19: set.fds_bits.19 = set.fds_bits.19 | mask
        case 20: set.fds_bits.20 = set.fds_bits.20 | mask
        case 21: set.fds_bits.21 = set.fds_bits.21 | mask
        case 22: set.fds_bits.22 = set.fds_bits.22 | mask
        case 23: set.fds_bits.23 = set.fds_bits.23 | mask
        case 24: set.fds_bits.24 = set.fds_bits.24 | mask
        case 25: set.fds_bits.25 = set.fds_bits.25 | mask
        case 26: set.fds_bits.26 = set.fds_bits.26 | mask
        case 27: set.fds_bits.27 = set.fds_bits.27 | mask
        case 28: set.fds_bits.28 = set.fds_bits.28 | mask
        case 29: set.fds_bits.29 = set.fds_bits.29 | mask
        case 30: set.fds_bits.30 = set.fds_bits.30 | mask
        case 31: set.fds_bits.31 = set.fds_bits.31 | mask
        default: break
    }
}



