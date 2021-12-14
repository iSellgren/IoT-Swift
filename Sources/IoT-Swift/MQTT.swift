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
    
    func sendPingResponse(client:Int32, buffer:UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8){
        
        print("header",header)
        let connectMessage = MQTTConnectMessage.init()
        let messageType = connectMessage.getMessageType(header: header)
        print("messageType", messageType)
        if(messageType == 12){
            send(client, responseMessage, responseMessage.capacity,0)
        }
    }
}
class DisconnectMessage{
    let disconnectMessage:[UInt8] = [(0xE0), (0x00)]
    func sendDisconnectAck(client:Int32, buffer:UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8){
        
        let connectMessage = MQTTConnectMessage.init()
        let messageType = connectMessage.getMessageType(header: header)
        if(messageType == 14){
            close(client)
        }
    }
}

class PublishMessage{
    
    func sendpublishAck(client:Int32, buffer:UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8){
        
        let publishMessage = MQTTPublishMessage.init()
        let messageType = publishMessage.getMessageType(header: header)

        if(messageType == 3)
        {
            let QoS = publishMessage.getQoS(header: header)
            let msgLen = Int(length)
//            let header = NSData(bytesNoCopy: header, length: 2)
            let data = NSData(bytesNoCopy: buffer, length: msgLen, freeWhenDone: false)
            let array = [UInt8](data)
            
            if(QoS == 0)
            {
                sendToAllInDict(client: client, topic: array, header: header, topiclength: msgLen, subFilters: subFilters)

            }
            if(QoS == 1)
            {
                let Message:[UInt8] = [(0x40), (0x02),(0x00), (0x01)]
                send(client, Message, Message.capacity,0)
                sendToAllInDict(client: client, topic: array, header: header, topiclength: msgLen, subFilters: subFilters)
            }
            if(QoS == 2)
            {
                let Message:[UInt8] = [(0x50), (0x02),(0x00), (0x01)]
                send(client, Message, Message.capacity,0)
            }
        }
        
        else if (messageType == 6){
            if(publishMessage.getReserved(header: header) != 2){
                print("Bits 3,2,1,0 is wrong closing connection PUBLISH")
                DisconnectMessage.init().sendDisconnectAck(client: client, buffer: buffer, length: length, header: header)
            }
            let Message:[UInt8] = [(0x70), (0x02),(0x00), (0x01)]
            send(client, Message, Message.capacity,0)
        }
    }
}


class UnsubscribeMessage{
    func getUnsubscribeMessage(client:Int32, buffer:UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8){
        let unsubscribeMessage = MQTTUnsubscribeMessage.init()
        let messageType = unsubscribeMessage.getMessageType(header: header)
        
        if(messageType == 10){
            if(unsubscribeMessage.getReservedQoS(buffer: buffer) != 0){
                print("Bits 3,2,1,0 is wrong closing connection SUBSCRIBE")
                DisconnectMessage.init().sendDisconnectAck(client: client, buffer: buffer, length: length, header: header)
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
    
    func getSubscribeMessage(client:Int32, buffer:UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8){
        let subscribeMessage = MQTTSubscribeMessage.init()
        let messageType = subscribeMessage.getMessageType(header: header)
        
        if(messageType == 8)
        {
            if(subscribeMessage.getReservedQoS(buffer: buffer) != 0){
                print("Bits 3,2,1,0 is wrong closing connection SUBSCRIBE")
                DisconnectMessage.init().sendDisconnectAck(client: client, buffer: buffer, length: length, header: header)
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
func sendToAllInDict(client: Int32, topic: [UInt8], header: UInt8, topiclength: Int, subFilters: [String:Array<Int32>]){
    print("-------")
    let fPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    fPointer[0] = header
    
    var totalLength = topic.count
    
    var lengthBytes: Array<UInt8> = []
    repeat {
        var b = UInt8(totalLength % 128)
        totalLength /= 128
        
        if totalLength > 0 {
            b |= 128
        }
        
        lengthBytes.append(b)
    } while(totalLength > 0)
    
    let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(lengthBytes.count))
    reSizeBuffer.initialize(from: lengthBytes, count: lengthBytes.count)
    for (filter,value) in subFilters{
        for i in value{
            send(i, fPointer, 1, 0)
            send(i, reSizeBuffer, lengthBytes.count, 0)
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
    
    func sendConnectAck(client:Int32, buffer:UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8){
        
        let connectMessage = MQTTConnectMessage.init()
        let messageType = connectMessage.getMessageType(header: header)
        print(messageType)
        
        if(messageType == 1){
            let messageLen = Int(length)
            print("Messagelen: ", messageLen)
            let protocolName = connectMessage.getProtocolName(buffer: buffer)
            let protocolNameLen = connectMessage.getProtocolNameLength(buffer: buffer)
            let version = connectMessage.getVersion(buffer: buffer)
            let clientIDLength = connectMessage.getClientIDLength(buffer: buffer)
            let clientName = connectMessage.getClientID(buffer: buffer)
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
            
            connectionQueue.async() {
                receiveAndDispatch(client: client)
                
            }
        }
    }
}
func receiveAndDispatch(client: Int32) {

    let dataProcessingQueue = DispatchQueue(label: "dataProcessingQueue", attributes: [.concurrent] )
    let headerSize = 1
    var headerBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(headerSize))
    
    reciveDataFromClients: while true {
        
        let readHeader = recv(client,headerBuffer,headerSize,0)
        
        // 1
        var header = headerBuffer[0]
        
        var multiplier: UInt32 = 1
        
        // 2
        var value: UInt32 = 0
        var encodedByte: UInt8
        repeat{
            recv(client,headerBuffer,headerSize,0)
            encodedByte = headerBuffer[0]
            value += UInt32(encodedByte & 127) * multiplier
            multiplier *= 128
        }while ((encodedByte & 128) != 0)
        
        let readBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(value))
        let readResult = recv(client,readBuffer,Int(value),0)
        print("hedsadsa")
        print(readResult)
        
        let newPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: headerSize + Int(value))
        newPtr.initialize(from: headerBuffer, count: headerSize)
        newPtr.advanced(by: headerSize).initialize(from: readBuffer, count: Int(value))
        
        let data = NSData(bytesNoCopy: newPtr, length:headerSize + Int(value), freeWhenDone: false)

        
        
        if readResult == -1 && readHeader == -1 {
            
            let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
            reSizeBuffer.initialize(from: readBuffer, count: readResult)
            DisconnectMessage.init().sendDisconnectAck(client: client, buffer: reSizeBuffer, length: value, header: header)
            break reciveDataFromClients
        }
        if readResult == 0 && readHeader == 0 {
            print("0")
            let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
            reSizeBuffer.initialize(from: readBuffer, count: readResult)
            DisconnectMessage.init().sendDisconnectAck(client: client, buffer: reSizeBuffer, length: value, header: header)
            break reciveDataFromClients
        }
        
        let message = "Received \(readResult) bytes from the client \(client)"
        print(message)
        
        let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
        reSizeBuffer.initialize(from: readBuffer, count: readResult)
        let bufferlength:Int = Int(MemoryLayout.size(ofValue: reSizeBuffer).self)
        processClientData(client: client, data: readBuffer, length: value, header: header)
    }
}
func processClientData(client: Int32,data: UnsafeMutablePointer<UInt8>, length: UInt32, header: UInt8) {
    print("insideProcessData")
    ConnectAckMessage.init().sendConnectAck(client: client, buffer: data, length: length, header: header)
    SubscribeMessage.init().getSubscribeMessage(client: client, buffer: data, length: length, header: header)
    UnsubscribeMessage.init().getUnsubscribeMessage(client: client, buffer: data, length: length, header: header)
    PublishMessage.init().sendpublishAck(client: client, buffer: data, length: length, header: header)
    PingResponse.init().sendPingResponse(client: client, buffer: data, length: length, header: header)
}
