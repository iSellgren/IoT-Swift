//
//  CoAP.swift
//  
//
//  Created by Fredrik Sellgren on 2021-11-12.
//

import Foundation
import AppKit

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
        
//        let hexArray:[UInt8] = [UInt8(64), UInt8(1), UInt8(4), UInt8(0xd2), UInt8(0xb4), UInt8(0x74), UInt8(0x65), UInt8(0x73), UInt8(0x74)]
//        let hexArray:[UInt8] = [UInt8(0x40), UInt8(0x01), UInt8(0x04), UInt8(0xd2), UInt8(0xb5),UInt8(0x68),UInt8(0x65),UInt8(0x6c), UInt8(0x6c), UInt8(0x6f)]
//                let hexArray:[UInt8] = [UInt8(0x40), UInt8(0x01), UInt8(0x04), UInt8(0xd2), UInt8(0xb1),UInt8(0x35)]
//                let hexArray:[UInt8] = [UInt8(0x40), UInt8(0x01), UInt8(0x04), UInt8(0xd2), UInt8(0xb4), UInt8(0x73), UInt8(0x65), UInt8(0x67), UInt8(0x31)]
//        Confirmable
        let VersionInput:UInt8 = 1
        let TypeInput:UInt8 = 0
        let TKLInput:UInt8 = 0
        
        let VersionBin:UInt8 = 0
        let TypeBin:UInt8 = 0
        let TklBin:UInt8 = 0
        var version = ((VersionBin) | VersionInput) << 2
        let type = ((TypeBin) | TypeInput) << 0
        
//        _ = version+type
        
        var tkl = (((TklBin) | TKLInput) << 0)
//        var secoundPart = tkl
//        print(firstPart, secoundPart)
//        var joinedPart = (firstPart << 4) | secoundPart
//        print(joinedPart)
//
        
        let firstMessageByte:UInt8 = UInt8((version << 4) + (type << 2) + (tkl))
        print(firstMessageByte, "version")
        
        let CodeInput:Int = 4
        
//        let secondMessageByte:UInt8 =
        
        let MessageID:UInt16 = 124
        var MessageIDFirst:UInt8 = 0
        var MessageIDSecond:UInt8 = 0
        
        MessageIDFirst = UInt8((MessageID >> 8) & 0xFF)
        MessageIDSecond = UInt8((MessageID & 0xFF))
        print(MessageIDFirst, MessageIDSecond)
        
        
        let Path:String = "sink"
        var PathArray:[UInt8] = []
        for values in Path.utf8 {
            PathArray.append(values)
        }
        let Payload:String = "FreddeWASHERE"
        var PayloadArray:[UInt8] = []
        for values in Payload.utf8 {
            PayloadArray.append(values)
        }

        let OptInputDelta = 11
        let OptInputLenght = Path.count
        
        let Opt = ((OptInputDelta << 4 ) + (OptInputLenght) << 0)
        
        print(Opt,"Opt")
        
        var hexArray:[UInt8] = [UInt8(firstMessageByte), UInt8(CodeInput), UInt8(MessageIDFirst), UInt8(MessageIDSecond), UInt8(Opt)]
        
        for i in 0..<Int(PathArray.count){
            hexArray.append(PathArray[i])
        }

        for i in 0..<Int(PayloadArray.count){
            if i == 0 {
                hexArray.append(0xFF)
            }
            hexArray.append(PayloadArray[i])
        }
    
        
        
//        let hexArray:[UInt8] = [UInt8(0x51), UInt8(0x01), UInt8(0x04), UInt8(0xd2), UInt8(0xb4), UInt8(0x73), UInt8(0x65), UInt8(0x67), UInt8(0x31)]
        
//        print(hexArray)
//        print(String(decoding: hexArray, as: UTF8.self))
        write(socket, hexArray, hexArray.count)
        let bufferSize:Int = 65536;

        let readBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))

        let readResult = read(socket, readBuffer, bufferSize)
        
//        print(readBuffer[0])
        
        let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
        reSizeBuffer.initialize(from: readBuffer, count: readResult)
        
        let message = String(cString: readBuffer)
        print(message)
        
        print(getVersion(buffer: reSizeBuffer))
        print(MessageTypes(rawValue: getT(buffer: reSizeBuffer))!)
//        print(getTLK(buffer: reSizeBuffer))
        print(ResponseCodes(rawValue: getCode(buffer: reSizeBuffer))!)
        
        print(getmessgeID(buffer: reSizeBuffer))
//        print(getTokenLenght(buffer: reSizeBuffer)[0])
        let options = getOptions(buffer: reSizeBuffer, size:readResult)
        let opts = options.0
        let payload = String(bytes: options.1, encoding: .utf8)!
        
//        print(ContentFormats(rawValue: Int(opts.last!.context[0]))!)
        
        
        print(payload)
//        let inta = getOptionType(buffer: reSizeBuffer, test: &opts)
        
        
        
        
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

enum MessageTypes: Int{
    case CONfirmable = 0
    case NONConfirmable = 1
    case ACKnowledgement = 2
    case ReSeT = 3
    
}

enum ContentFormats: Int {
    case textPlain = 0
    case applicationLinkFormat = 40
    case applicationXML = 41
    case applicationOctetStream = 42
    case applicationExi = 47
    case applicationJson = 50
    case applicationCbor = 60
}

enum MethodCodes: Int {
    case EMPTY = 0
    case GET = 1
    case POST = 2
    case PUT = 3
    case DELETE = 4
}

struct options {

    var delta: Int
    var length: Int
//    var value: [UInt8]
    var value: Int
    var context: [UInt8]
}
enum ResponseCodes: Int {
    case Created = 65
    case Deleted = 66
    case Vaild = 67
    case Changed = 68
    case Content = 69
    case Continue = 95
    case BadRequest = 128
    case Unauthorized = 129
    case BadOption = 130
    case Forbidden = 131
    case NotFound = 132
    case MethodNotAllowed = 133
    case NotAccepted = 134
    case RequestEntityIncomplete = 136
    case PreconditionFailed = 140
    case RequestEntityTooLarge = 141
    case UnsupportedContentFormat = 143
    case InternalServerError = 160
    case NotImplemented = 161
    case BadGateway = 162
    case ServiceUnavailable = 163
    case GatewayTimeout = 164
    case ProxyingNotSupported = 165
}


func getOptions(buffer:UnsafeMutablePointer<UInt8>, size:Int) -> ([options],[UInt8])
{
    let tokenLenght = UInt8(getTLK(buffer: buffer))
    
    
    var optionArray:[options] = []
    var payloadArray:[UInt8] = []
    var j = (Int(tokenLenght)+4)
    var deltaSum = 0
    while(j < size){
    
        if UInt8(buffer[j]) == 0xff{
            j += 1
            if(j < size)
            {
                print("hello")
                for i in (j..<size) {
                    payloadArray.append(UInt8(buffer[i]))
                }
            }
            return (optionArray, payloadArray)
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
        
        if Optlength != 0 && optDelta != 12{
            for _ in (0..<Optlength)
            {
                let value = Int(buffer[j])
                OptValue.append(UInt8(value))
                j+=1
            }
        }
        else if (Optlength == 0) && optDelta >= 1{
            OptValue.append(0)
        }
        else if (Optlength == 0) && optDelta >= 9 {
            OptValue.append(UInt8(Int(buffer[(Int(tokenLenght) + 4 + optDelta + deltaSum - 2)])))
        }
        let option = options(delta: optDelta, length: Optlength, value: optDelta + deltaSum , context: OptValue )
        deltaSum += optDelta
        optionArray.append(option)
    }
    return (optionArray, [])
}

//func getOptionType(buffer:UnsafeMutablePointer<UInt8>, test: inout [options]) -> [Int] {
//    let tokenLenght = UInt8(getTLK(buffer: buffer))
////    Try to get ContentFormat
//    var optionTypeArray:[Int] = []
//    for i in 0..<Int(test.count){
//
//
//        if((test[i].delta) == 12){
//        print(test[i].delta)
//        if (test.count == 1 || test[i].length == 0) {
//            optionTypeArray.append(0)
//
//        }
//
//        optionTypeArray.append(Int(buffer[(Int(tokenLenght)+4+test[i].delta - 2)]))
//        }
//    }
//    print(optionTypeArray)
//    return optionTypeArray
//}
