
//
//  Server.swift
//  IoT-protocols
//
//  Created by Fredrik Sellgren on 2021-11-03.
//

import Foundation

struct users : Codable {
    let Id: Int
    let Name : String
}

class Server {
    let serverPort:String
    var jsonArray = [users]()
    init(port: UInt16) {
         serverPort = String(port)
       }
    func start (){
        var requestCount:Int = 0
//        Creating the socket
        let socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        
        if socket == -1
        {
            print("Error when creating socket")
            return
        }
//        Force to use the specified port
        var use_opt:Int32 = 0
        let sizeOfUseOpT:UInt32 = UInt32(MemoryLayout.size(ofValue: use_opt).self)
        
        if (setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &use_opt, sizeOfUseOpT) != 0){
            print("Fail to get socketPort")
        }
        
        var identifyHost = addrinfo(ai_flags: AI_PASSIVE, ai_family: AF_INET, ai_socktype: SOCK_STREAM, ai_protocol: 0, ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil)
        
        var addrInfoPointer: UnsafeMutablePointer<addrinfo>? = nil
        
        let resultFromAddrInfo: Int32
        
        resultFromAddrInfo = getaddrinfo(nil, serverPort, &identifyHost, &addrInfoPointer)
        print(resultFromAddrInfo)
        if resultFromAddrInfo != 0 {
            print("Error getting information from address ErrorCode: \(errno)")
        }

        
//        Creates an instance intended for a server socket for the given `port` that will be used with `bind()`.
        let binding: Int32
        binding = bind(socket, addrInfoPointer!.pointee.ai_addr, socklen_t(addrInfoPointer!.pointee.ai_addrlen))
//        print(binding)
        
        if binding == -1
        {
            print("Error binding socket to address ErrorCode: \(errno)")
            return
        }
        
        let connectionQueue: Int32 = 1
        let listenToSocket:Int32 = listen(socket, connectionQueue)

        print(listenToSocket)
        if listenToSocket == -1
        {
            print("Error: Cant lisen to socket ErrorCode: \(errno)")
            return
        }
        
        while true {

            let bufferSize:Int32 = 65536;
            var socketAdress:sockaddr = sockaddr()
            var socketAdressLength:UInt32 = UInt32(MemoryLayout.size(ofValue: socketAdress).self)
            
            print("Ready to for new call")
            let client = accept(socket, &socketAdress, &socketAdressLength)

            let readBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: Int(bufferSize))

            let readResult = recv(client, readBuffer, Int(Int32(bufferSize)),0)
            
            if readResult < 0
            {
                print("Error reading form client\(client) - \(errno)")
            }

            
            let str = String(cString: readBuffer)
            print(str)
            
            let _: Void = requestHTTPHandler(buffer: str, client: client, reqNr :&requestCount, jsonArray: &jsonArray)
        }
    }
}


func test(buffer:String, content:String) -> String {
    
    var getContent:String = ""
    if let range: Range<String.Index> = buffer.range(of: content) {
        let index: Int = buffer.distance(from: buffer.startIndex, to: range.lowerBound)
        let getBody = buffer.index(buffer.startIndex, offsetBy: String.IndexDistance(index+content.count))
        getContent = String(buffer[getBody...])
        return getContent
        
    }
    return ""
}


func test1(buffer:String, content:String, chars:String) -> String
{
    if let range: Range<String.Index> = content.range(of: chars){
        let index: Int = buffer.distance(from: content.startIndex, to: range.upperBound)
        let getTestBody = content.index(content.startIndex, offsetBy: String.IndexDistance(index-chars.count))
        let getContentMessage = String(content[...getTestBody])
    
        return getContentMessage
    }
    return ""
}


func getTextToJson (buffer: String , `var`requestCount:Int) -> String {
    
    var string = ""
    let getBodyMessage:String = test(buffer: buffer, content: "Name")
    
    string = test1(buffer: buffer, content: getBodyMessage, chars: ",\n")
    
    if string == "" && !getBodyMessage.isEmpty{
        string = getBodyMessage
    }
    let filteredGetContentType = string.filter{$0.isLetter};
    let trimmedString = filteredGetContentType.components(separatedBy: .whitespacesAndNewlines).joined()
    
    let xmpl = users(Id: requestCount ,Name: trimmedString)
    let jsonEncoder = JSONEncoder()
    let jsonData = try! jsonEncoder.encode(xmpl)
    let json = (String(data: jsonData, encoding: String.Encoding.utf8)!)
    return json
}

func getHeaderInfo(HTTPBody: String, HeaderKey: String) -> String{
    
    let formatString = HeaderKey + ":"
    print(formatString.count)
    var string = ""
    let getBodyMessage:String = test(buffer: HTTPBody, content: formatString)

    string = test1(buffer: HTTPBody, content: getBodyMessage, chars: "\r\n")
    
    let filteredGetContentType = string.filter{$0.isLetter || $0.isWhitespace || $0.isNumber || $0.isASCII};
    let trimmedString = filteredGetContentType.components(separatedBy: .whitespacesAndNewlines).joined()
    return trimmedString
}



func getBodyMessage (HTTPBody: String) -> String{
    let getBodyMessage:String = test(buffer: HTTPBody, content: "\r\n")
    
    let filteredGetBodyMessage = getBodyMessage.filter{$0.isLetter || $0.isWhitespace || $0.isNumber || $0.isASCII};
    return filteredGetBodyMessage;
    
}

func getHTTPMethod (HTTPMethod: String) -> String{
    
    let getMethod = (HTTPMethod.components(separatedBy: " ") as NSArray).object(at: 0)
    return getMethod as! String
}
func getURLParams (HTTPParams: String, HTTPMethod: String) -> String{
    
    let string = (HTTPParams.components(separatedBy: " ") as NSArray).object(at: 1)
    print(HTTPMethod)
    let buffer:String = string as! String
    print(buffer)
    if HTTPMethod == "POST"{
        let getBodyMessage:String = test(buffer: buffer, content: "Name")
        let MakeItWork:String = "Name:   " + getBodyMessage
        return MakeItWork
    }
    else if HTTPMethod == "GET"{
        return buffer
    }
    return ""
}


func writePostJSONToFile(items: [users]) {
    do {
        let fileURL = URL(fileURLWithPath: "storage.json")
        let encoder = JSONEncoder()
        try encoder.encode(items).write(to: fileURL)
    } catch {
        print(Error.self)
    }
}

func encodeStringToJson(json:String, array:inout [users]) ->String{
    guard let string = json.data(using: .utf8) else { return"" }
    let test = try? JSONDecoder().decode(users.self, from: string)
    array.append(test!)
    writePostJSONToFile(items: array)
    
    let out = try? JSONEncoder().encode(array)
    return String(data: out!, encoding: String.Encoding.utf8)!
}

func requestHTTPHandler(buffer:String, client:Int32, reqNr:inout Int, jsonArray:inout [users]) -> Void {
    
    
    let HTTPMethod = getHTTPMethod(HTTPMethod: buffer)
    let contentType = String(getHeaderInfo(HTTPBody: buffer, HeaderKey: "Content-Type"))
    if(HTTPMethod == "POST"){
        
        let HTTPBody = getBodyMessage(HTTPBody: buffer)

        let contentLenght:Int = Int(getHeaderInfo(HTTPBody: buffer, HeaderKey: "Content-Length"))!
        if contentType == "text/plain" && contentLenght != 0
        {
            reqNr += 1
            let json = getTextToJson(buffer: HTTPBody, var: reqNr)
            let output = encodeStringToJson(json: json, array: &jsonArray)
        
            let msg: String = "HTTP/1.1 200 OK \r\nContent-Type: " + contentType + "\r\n\r\n" + output + "\r\n"

            sendMessageToClient(client: client, message: msg)
        }
        
        else if contentType == "application/json" && contentLenght != 0
        {
            reqNr += 1
            let json = getTextToJson(buffer: HTTPBody, var: reqNr)
            let output = encodeStringToJson(json: json, array: &jsonArray)
        
            let msg: String = "HTTP/1.1 200 OK \r\nContent-Type: " + contentType + "\r\n\r\n" + output + "\r\n"
            sendMessageToClient(client: client, message: msg)
        } else if contentLenght == 0
        {
            reqNr += 1
            let urlParams = getURLParams(HTTPParams: buffer, HTTPMethod: HTTPMethod)
            let json = getTextToJson(buffer: urlParams, var: reqNr)

            let output = encodeStringToJson(json: json, array: &jsonArray)
            
            let msg: String = "HTTP/1.1 200 OK \r\nContent-Type: " + contentType + "\r\n\r\n" + output + "\r\n"
            sendMessageToClient(client: client, message: msg)
        }
        
        else {
            let msg: String = "HTTP/1.1 400 Bad Reqeust Error \r\nContent-Type: " + contentType + "\r\n\r\n" + "Bad Request" + "\r\n" + "Unsupported Content-Type: " + contentType
            sendMessageToClient(client: client, message: msg)
        }
        
    }
    else if(HTTPMethod == "GET"){
        let test = getURLParams(HTTPParams: buffer, HTTPMethod: HTTPMethod)
        if test == "/users" {
                do {
                    let fileURL = URL(fileURLWithPath: "storage.json")
                    let text = try String(contentsOf: fileURL, encoding: .utf8)
                    let msg: String = "HTTP/1.1 200 OK \r\nContent-Type: " + "application/json" + "\r\n\r\n" + text + "\r\n"
                    sendMessageToClient(client: client, message: msg)
                }
                catch {/* error handling here */}
            }else{
            let msg: String = "HTTP/1.1 400 Bad Reqeust Error \r\nContent-Type: " + contentType + "\r\n\r\n" + "Bad Request" + "\r\n"
            sendMessageToClient(client: client, message: msg)
        }

    }else if(HTTPMethod == "PUT"){
        
    }else if(HTTPMethod == "DELETE"){
        
    }
}



func sendMessageToClient(client:Int32, message:String)
{
    send(client, message, message.lengthOfBytes(using: String.Encoding.utf8),0)
    close(client)
}

func checkIfFileExists(name:String){
    let filePath = NSHomeDirectory() + "/IoT-Swift" + "/Sources"+"/IoT-Swift" + "/"+name
    let hasFile = FileManager().fileExists(atPath: filePath)
    if hasFile {
        print("File Exists")
    }
    else {
        print("File dont Exists")
    }
}

func createTxtFile(name: String){
    let filePath = NSHomeDirectory() + "/IoT-Swift" + "/Sources" + "/IoT-Swift" + "/"+name
    if (FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)) {
        print("File created successfully.")
    } else {
        print("File not created.")
    }
}

