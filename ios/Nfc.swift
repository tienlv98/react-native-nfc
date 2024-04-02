import Foundation
import CoreNFC
import JavaScriptCore

private var cryptoJScontext = JSContext()

@objc(Nfc)
@available(iOS 13.0, *)
class Nfc: NSObject, NFCNDEFReaderSessionDelegate{
    var session: NFCNDEFReaderSession?
    var dataWrite: NFCNDEFMessage?
    var dataRead: NFCNDEFMessage?
    var dataJs: String?
    var callback: RCTResponseSenderBlock?
    var encryptFunction: JSValue?
    var decryptFunction: JSValue?
    var resolveGlobal: RCTPromiseResolveBlock?
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {

    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("messages",messages)
    }
    
    func giftZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag, didDetect data: NFCNDEFMessage){
        session.connect(to: tag){ (error: Error?) in
            tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                print("message",message)
                session.alertMessage = "read okla"
                if error != nil {}
                else {
                    session.restartPolling()
                }
            })
            
            tag.writeNDEF(data) { (error: Error?) in
                if error != nil {
                    print("error")
                    session.alertMessage = "Update error write 0"
                    session.restartPolling()
                    
                } else {
                    print("success")
                    session.alertMessage = "Update success write 1"
                    session.invalidate()
                }
            }
        }
    }
    
    func readZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag){
        session.connect(to: tag){ (error: Error?) in
            tag.readNDEF(completionHandler: { [self] (message: NFCNDEFMessage?, error: Error?) in
                session.alertMessage = "read okla"
                if error != nil && message != nil {
                   
                }
                else {
                    session.restartPolling()
                }
                session.invalidate()
                let data = [String(decoding: (message?.records[0].payload)!, as: UTF8.self),String(decoding: (message?.records[1].payload)!, as: UTF8.self)]
                print("daddadadadadada tag ",data)
                let data2 = "U2FsdGVkX1/+5s95qtaccKgLCC5AKSU9bGTUQRnvd3dlNqvfXCf6dTN86EJwUEOPmiSZItJpejTXPvBLZCNp63jJsJxGVcQNr4hH/o3BeThbud3uJX6j6IxX+VyB7xdq"
                let mnemonic = "delay card fiction vacant athlete buyer tower cinnamon april bus jacket enforce"
                let pass = "1234123412341234"
                let ddadadaad = "\(self.encryptFunction!.call(withArguments: [mnemonic, pass])!)"
                let ddadadaad2 = "\(self.decryptFunction!.call(withArguments: [data2, pass])!)"
                print("data after encryptFunction",ddadadaad)
                print("data after decryptFunction",ddadadaad2)
                
                
                self.resolveGlobal!(data)
            })
        }
    }
    
    func writeZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag, didDetect data: NFCNDEFMessage){
        session.connect(to: tag){ (error: Error?) in
            tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                print("message",message)
                session.alertMessage = "read okla"
                if error != nil {}
                else {
                    session.restartPolling()
                }
                self.dataRead = message
            })
            tag.writeNDEF(data) { (error: Error?) in
                
                let data = [String(decoding: (self.dataRead?.records[0].payload)!, as: UTF8.self),String(decoding: (self.dataRead?.records[1].payload)!, as: UTF8.self)]
                print("data",data)
                if error != nil {
                    print("error")
                    session.alertMessage = "Update error write 0"
                    session.restartPolling()
                    
                } else {
                    print("success")
                    session.alertMessage = "Update success write 1"
                    session.invalidate()
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession,didDetect tags: [NFCNDEFTag]){
        let tag = tags.first!
        print("tags",tag)
        let dataTag = NFCNDEFPayload(format: NFCTypeNameFormat.media,
                                     type: "text/plain".data(using: .utf8)!,
                                     identifier: Data.init(count: 0),
                                     payload: "nam thang manh thuong quan (nami)".data(using: .utf8)!)
        let ndefMessage = NFCNDEFMessage(records: [dataTag,dataTag,dataTag])
        
        self.writeZen(session,didDetect: tag,didDetect: ndefMessage)
        
    }
    
    func connect(mess: String){
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = mess
        session?.begin()
    }
    
    @objc(gift:giftRejecter:)
    func gift (resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock){
        self.connect(mess: "Hold to die(gift)")
        resolveGlobal = resolve
    }
    @objc(read:readRejecter:)
    func read(resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(read)")
        resolveGlobal = resolve
    }
    @objc(write:writeResolver:writeRejecter:)
    func write(data: String,resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(write)")
        resolveGlobal = resolve
    }
    
    @objc(sendData:)
    func sendData(data:String) -> Void {
        print("sendData",data)
        dataJs = data
    }
    
    @objc(test:testCallback:)
    func test(dataTest:Array<Double>,callbackMethod:@escaping RCTResponseSenderBlock){
        print("dataTest",dataTest)
        
        let cryptoJSpath = Bundle.main.path(forResource: "aes", ofType: "js")
        do {
            let cryptoJS = try String(contentsOfFile: cryptoJSpath!, encoding: String.Encoding.utf8)
            print("Loaded aes.js")
            _ = cryptoJScontext?.evaluateScript(cryptoJS)
            encryptFunction = cryptoJScontext?.objectForKeyedSubscript("encrypt")
            decryptFunction = cryptoJScontext?.objectForKeyedSubscript("decrypt")
        }
                        catch {
                            print("Unable to load aes.js")
                        }
//        callback = callbackMethod
    }
}
