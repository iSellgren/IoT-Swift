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
    
    func start (){
        let connect = CoAPConnection()
        let socket = connect.startConnection()
        
        let VersionInput:UInt8 = 1
        
        print("<--SELECT MESSAGE TYPE-->")
        for msgTypes in MessageTypes.allCases {
            print("\(msgTypes.rawValue) -> \(msgTypes)")
        }
        
        let TypeInput:UInt8 = UInt8(Int(readLine()!)!)
        let TKLInput:UInt8 = 0
        let VersionBin:UInt8 = 0
        let TypeBin:UInt8 = 0
        let TklBin:UInt8 = 0
        let version = ((VersionBin) | VersionInput) << 2
        let type = ((TypeBin) | TypeInput) << 0
    
        
        let tkl = (((TklBin) | TKLInput) << 0)
        
        let firstMessageByte:UInt8 = UInt8((version << 4) + (type << 2) + (tkl))
        print("<--SELECT METHOD-->")
        for msgTypes in MethodCodes.allCases {
            print("\(msgTypes.rawValue) -> \(msgTypes)")
        }
        
        var CodeInput:Int? = nil
        let MethodInput = readLine()
        if let num = Int(MethodInput!) {
            CodeInput = num
        }
//        let secondMessageByte:UInt8 =
        print("<--SELECT MESSAGE ID 0 <-> 65535-->")
        let MessageID:UInt16 =  UInt16(Int(readLine()!)!)
        var MessageIDFirst:UInt8 = 0
        var MessageIDSecond:UInt8 = 0
        
        MessageIDFirst = UInt8((MessageID >> 8) & 0xFF)
        MessageIDSecond = UInt8((MessageID & 0xFF))
        
//        print(MessageIDFirst, MessageIDSecond)
        
        
        print("<--ENTER PATH-->")
        let Path:String = readLine()!
        var PathArray:[UInt8] = []
        for values in Path.utf8 {
            PathArray.append(values)
        }
        
        let OptInputDelta = OptionValues.UriPath.rawValue
        let OptInputLenght = Path.count
        
        let Opt = ((OptInputDelta << 4 ) + (OptInputLenght))
        
        
        
        
        var hexArray:[UInt8] = [UInt8(firstMessageByte), UInt8(CodeInput ?? 0), UInt8(MessageIDFirst), UInt8(MessageIDSecond), UInt8(Opt)]
        
        for i in 0..<Int(PathArray.count){
            hexArray.append(PathArray[i])
        }
        var fixPayload = ""
        if CodeInput == 2 || CodeInput == 3
        {
            print("<--ENTER PAYLOAD-->")
            let Payload:String = readLine()!
            var PayloadArray:[UInt8] = []
            for values in Payload.utf8 {
                PayloadArray.append(values)
            }
            for i in 0..<Int(PayloadArray.count){
                if i == 0 {
                    fixPayload = Payload
                    hexArray.append(0xFF)
                }
                hexArray.append(PayloadArray[i])
            }
        }
        print("Writing | Ver: \(VersionInput) | T: \(MessageTypes(rawValue: Int(TypeInput))!) | TKL: \(tkl) | Code: \(MethodCodes(rawValue: Int(CodeInput!))!) | Message ID \(MessageID) | \n | Token: \(0) | Option: \(OptionValues(rawValue: OptInputDelta)!): \(Path)   | \(0xFF) | Payload: \(fixPayload) \n\n")
        
        
        write(socket, hexArray, hexArray.count)
        
        
        let bufferSize:Int = 65536;

        let readBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))

        let readResult = read(socket, readBuffer, bufferSize)
        
        let reSizeBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(readResult))
        reSizeBuffer.initialize(from: readBuffer, count: readResult)
        
        
        var printMessage = "Reading | Ver: \(getVersion(buffer: reSizeBuffer)) | T: \(MessageTypes(rawValue: getT(buffer: reSizeBuffer))!) | TKL: \(getTLK(buffer: reSizeBuffer)) | Code: \(ResponseCodes(rawValue: getCode(buffer: reSizeBuffer))!) | Message ID \(getmessgeID(buffer: reSizeBuffer)) | \n | Options: "
        
        let options = getOptions(buffer: reSizeBuffer, size:readResult)
        let payload = String(bytes: options.1, encoding: .utf8)!
        
        var OptName = ""
        var index = 1
        for values in options.0{

            OptName += "OPT Name: #\(index): "
            index += 1
            OptName += "\(OptionValues(rawValue: values.value)!): "
            if(values.value == 12){
                OptName += "\(ContentFormats(rawValue: Int(values.context[0]))!)"
            }
            if(values.value == 8)
            {
                for val in values.context
                {

                    OptName += (String(format: "%c", val) as String)
                }
            }
            if(values.value == 23)
            {
                print(Opt)
                var blockArray:[UInt8] = [UInt8(firstMessageByte), UInt8(CodeInput ?? 0), UInt8(MessageIDFirst), UInt8(MessageIDSecond+1), UInt8(Opt)]
                for i in 0..<Int(PathArray.count){
                    blockArray.append(PathArray[i])
                }
                
                let OptBlock2 = 12
                let OptBlock2Lenght = 1
                let Block2Opt = ((OptBlock2 << 4 ) + (OptBlock2Lenght << 0))
                
                blockArray.append(UInt8(Block2Opt))
                for val in values.context
                {
                    print(val)
                    blockArray.append(UInt8(val))
                }
                print(blockArray)
                write(socket, blockArray, blockArray.count)
            }
            if(values.value == 4){
                for val in values.context
                {
                    OptName += String(format:"%02X", val) + " "
                }
            }
            printMessage += OptName + " | "
            OptName = ""
        }
        
        printMessage += "Payload: " + payload
        print(printMessage)
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

enum OptionValues: Int, CaseIterable {
    case IFMatch = 1
    case UriHost = 3
    case ETag = 4
    case IFNoneMatch = 5
    case UriPort = 7
    case LocationPath = 8
    case UriPath = 11
    case ContentFormat = 12
    case MaxAge = 14
    case UriQuery = 15
    case Accept = 17
    case LocationQuery = 20
    case Size2 = 28
    case ProxyUri = 35
    case ProxyScheme = 39
    case Size1 = 60
    case Block2 = 23
    case Block1 = 27
    
}

enum MessageTypes: Int, CaseIterable{
    case CONfirmable = 0
    case NONConfirmable = 1
    case ACKnowledgement = 2
    case ReSeT = 3
    
}

enum ContentFormats: Int, CaseIterable {
    case textPlain = 0
    case applicationLinkFormat = 40
    case applicationXML = 41
    case applicationOctetStream = 42
    case applicationExi = 47
    case applicationJson = 50
    case applicationCbor = 60
}

enum MethodCodes: Int, CaseIterable {
//    case EMPTY = 0
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
        
        if(optDelta + deltaSum == 23)
        {
            print("BLOCK")
            let value:Int = Int(buffer[j])
            print(value)
            let blockNr = ((Int(value) & 0b11110000) >> 4)
            let MoreFlags = ((Int(value) & 0b0001000) >> 3)
            let blockSize = Int(((powf(2,Float((((Int(value) & 0b00000111) << 0)+4))))))
            
            let BlockByte = blockNr + MoreFlags + blockSize
            print(BlockByte,"blockByte")
//            OptValue.append(UInt8(blockNr))
//            OptValue.append(UInt8(MoreFlags))
//            OptValue.append(UInt8(blockSize))
            OptValue.append(UInt8(BlockByte))
            
            j+=1
        }
            
        
        else if Optlength != 0 && optDelta != 12{
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

func getOptionType(buffer:UnsafeMutablePointer<UInt8>, test: inout [options]) -> [Int] {
    let tokenLenght = UInt8(getTLK(buffer: buffer))
//    Try to get ContentFormat
    var optionTypeArray:[Int] = []
    for i in 0..<Int(test.count){


        if((test[i].delta) == 12){
        print(test[i].delta)
        if (test.count == 1 || test[i].length == 0) {
            optionTypeArray.append(0)

        }

        optionTypeArray.append(Int(buffer[(Int(tokenLenght)+4+test[i].delta - 2)]))
        }
    }
    print(optionTypeArray)
    return optionTypeArray
}
