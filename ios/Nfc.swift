import Foundation
import CoreNFC
import JavaScriptCore

private var cryptoJScontext = JSContext()
private let SECTOR_SIZE = 16

@objc(Nfc)
@available(iOS 13.0, *)
class Nfc: NSObject, NFCNDEFReaderSessionDelegate{
    var session: NFCNDEFReaderSession?
    var dataWrite: String?
    var dataRead: [String]?
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
    
    func giftZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag) async {
        do {
            try await session.connect(to: tag)
            let datatag: NFCNDEFMessage = try await tag.readNDEF()
            let dataEncryped = String(decoding: (datatag.records[0].payload), as: UTF8.self)
            let pass = String(decoding: (datatag.records[1].payload), as: UTF8.self)
            let mnemonic = "\(self.decryptFunction!.call(withArguments: [dataEncryped, pass])!)"
            print("mnemonic",self.decryptFunction,pass)

            let splitForDevice = String(dataEncryped.suffix(dataEncryped.count - SECTOR_SIZE))
            let splitForCard = String(dataEncryped.prefix(SECTOR_SIZE))
            print("splitForDevice",splitForDevice)
           
            let ndefMessage = NFCNDEFMessage(records: [
                NFCNDEFPayload(format: NFCTypeNameFormat.nfcWellKnown,
                                             type: "text/plain".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: splitForCard.data(using: .utf8)!),
                NFCNDEFPayload(format: NFCTypeNameFormat.nfcWellKnown,
                                             type: "text/plain".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: pass.data(using: .utf8)!)
            ])
            
            print("write",write)
            
            try await tag.writeNDEF(ndefMessage)
            session.alertMessage = "Update success write"
            session.invalidate()
            self.resolveGlobal!([mnemonic,splitForDevice])
        }
        catch{
            session.alertMessage = "Update error write"
            session.restartPolling()
        }
    }
    
    func readZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag){
        session.connect(to: tag){ (error: Error?) in
            tag.readNDEF(completionHandler: { [self] (message: NFCNDEFMessage?, error: Error?) in
                if error != nil && message != nil {
                   
                }
                else {
                    session.restartPolling()
                }
                session.alertMessage = "read okla"
                session.invalidate()
                let splitForCard = String(decoding: (message?.records[0].payload)!, as: UTF8.self)
                let pass = String(decoding: (message?.records[1].payload)!, as: UTF8.self)
                let mnemonic = "\(self.decryptFunction!.call(withArguments: [splitForCard + self.dataWrite!, pass])!)"
                self.resolveGlobal!(mnemonic)
            })
        }
    }
    
    func writeZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag) async {
        do {
            try await session.connect(to: tag)
            let datatag: NFCNDEFMessage = try await tag.readNDEF()
//            let splitForCard = String(decoding: (datatag.records[0].payload), as: UTF8.self)
            let pass = String(decoding: (datatag.records[1].payload), as: UTF8.self)
            let dataEncryped = "\(self.encryptFunction!.call(withArguments: [self.dataWrite!, pass])!)"
            let splitForDevice = String(dataEncryped.suffix(dataEncryped.count - SECTOR_SIZE))
            let splitForCard = String(dataEncryped.prefix(SECTOR_SIZE))
            print("splitForDevice",splitForDevice)
           
            let ndefMessage = NFCNDEFMessage(records: [
                NFCNDEFPayload(format: NFCTypeNameFormat.media,
                                             type: "text/plain".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: splitForCard.data(using: .utf8)!),
                NFCNDEFPayload(format: NFCTypeNameFormat.media,
                                             type: "text/plain".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: pass.data(using: .utf8)!)
            ])
            
            print("write",write)
            
            try await tag.writeNDEF(ndefMessage)
            session.alertMessage = "Update success write"
            session.invalidate()
            self.resolveGlobal!(splitForDevice)
        }
        catch{
            session.alertMessage = "Update error write"
            session.restartPolling()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession,didDetect tags: [NFCNDEFTag]){
        let tag = tags.first!
        Task{
            await self.giftZen(session,didDetect: tag)
        }
    }
    
    func connect(mess: String){
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = mess
        session?.begin()
    }
    
    @objc(gift:giftRejecter:)
    func gift(resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock){
        self.connect(mess: "Hold to die(gift)")
        resolveGlobal = resolve
    }
    @objc(read:readResolver:readRejecter:)
    func read(splitForDevice: String,resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(read)")
        resolveGlobal = resolve
        dataWrite = splitForDevice
    }
    @objc(write:writeResolver:writeRejecter:)
    func write(mnemonic: String,resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(write)")
        resolveGlobal = resolve
        dataWrite = mnemonic
    }
    
    @objc(initNfc:initRejecter:)
    func initNfc(resolve: RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock){
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

    }
}
