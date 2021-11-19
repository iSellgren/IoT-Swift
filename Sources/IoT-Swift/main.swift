import Foundation

//var runServer = false
//
//let firstargument = CommandLine.arguments[1]
//print(firstargument)
//switch(firstargument){
//case "-l":
//    runServer = true
//default:
//    break
//}
//
//if runServer {
//    if let portNr = UInt16(CommandLine.arguments[2]){
//        print("Starting server on port: \(portNr)")
//        let server = Server(port: portNr)
//        server.start()
//    }
//}else {
    print("Starting as CoAP")
    let coap = CoAP()
    coap.start()
//}
exit(EXIT_SUCCESS)

