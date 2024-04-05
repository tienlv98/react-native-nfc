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
    var rejectGlobal: RCTPromiseRejectBlock?
    var funcZen: Int?
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {

    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("messages",messages)
    }
    
    func giftZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag) async {
        do {
            try await session.connect(to: tag)
            let datatag: NFCNDEFMessage = try await tag.readNDEF()
            let dataTag0 = String(decoding: (datatag.records[0].payload[3...]), as: UTF8.self)
            let dataTag1 = String(decoding: (datatag.records[1].payload[3...]), as: UTF8.self)
            
            let sizeTag = datatag.records.count
            var (key,pass) = (dataTag1,dataTag0)
            
            if(sizeTag>2){
                (key,pass) = (dataTag0,dataTag1)
            }
            
            let mnemonic = "\(self.decryptFunction!.call(withArguments: [key, pass])!)"
            if(mnemonic.count == 0 || mnemonic == "undefined") {
                self.rejectGlobal!("decrypt error","decrypt error",nil)
                session.invalidate(errorMessage: "decrypt error")
                return
            }
            print("mnemonic",mnemonic,mnemonic.count)
            let splitForDevice = String(key.suffix(key.count - SECTOR_SIZE))
            let splitForCard = String(key.prefix(SECTOR_SIZE))
            
            var passForCard = Data([0x02,0x65,0x6E])
            passForCard.append(pass.data(using: .utf8)!)
                        
            var keyForCard = Data([0x02,0x65,0x6E])
            keyForCard.append(splitForCard.data(using: .utf8)!)
           
            let ndefMessage = NFCNDEFMessage(records: [
                NFCNDEFPayload(format: NFCTypeNameFormat.nfcWellKnown,
                                             type: "T".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: passForCard),
                NFCNDEFPayload(format: NFCTypeNameFormat.nfcWellKnown,
                                             type: "T".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: keyForCard)
            ])
            
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
                let sizeTag = message!.records.count
                
                let tagIndex0 = String(decoding: (message?.records[0].payload[3...])!, as: UTF8.self)
                let tagIndex1 = String(decoding: (message?.records[1].payload[3...])!, as: UTF8.self)
                
                session.alertMessage = "read okla"
                session.invalidate()
                
                // [key , pass]
                if(sizeTag>2){
                    self.resolveGlobal!([tagIndex0,tagIndex1])
                } else {
                    self.resolveGlobal!([tagIndex1,tagIndex0])
                }
                
            })
        }
    }
    
    func writeZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag) async {
        do {
            try await session.connect(to: tag)
            let datatag: NFCNDEFMessage = try await tag.readNDEF()
            let sizeTag = datatag.records.count
            var indexTagPass = 0
            if(sizeTag>2){
                indexTagPass = 1
            }
            let pass = String(decoding: (datatag.records[indexTagPass].payload)[3...], as: UTF8.self)
            let dataEncryped = "\(self.encryptFunction!.call(withArguments: [self.dataWrite!, pass])!)"
            if(dataEncryped.count == 0 || dataEncryped == "undefined") {
                self.rejectGlobal!("encrypt error","encrypt error",nil)
                session.invalidate(errorMessage: "encrypt error")
                return
            }
            
            let splitForDevice = String(dataEncryped.suffix(dataEncryped.count - SECTOR_SIZE))
            let splitForCard = String(dataEncryped.prefix(SECTOR_SIZE))
            
            var passForCard = Data([0x02,0x65,0x6E])
            passForCard.append(pass.data(using: .utf8)!)
            
            var keyForCard = Data([0x02,0x65,0x6E])
            keyForCard.append(splitForCard.data(using: .utf8)!)
            
            let ndefMessage = NFCNDEFMessage(records: [
                NFCNDEFPayload(format: NFCTypeNameFormat.nfcWellKnown,
                                             type: "T".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: passForCard),
                NFCNDEFPayload(format: NFCTypeNameFormat.nfcWellKnown,
                                             type: "T".data(using: .utf8)!,
                                             identifier: Data.init(count: 0),
                                             payload: keyForCard)
            ])
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
            switch self.funcZen {
            case 0:
                await self.giftZen(session,didDetect: tag)
            case 1:
                self.readZen(session,didDetect: tag)
            case 2:
                await self.writeZen(session,didDetect: tag)
            default:
                print("error")
            }
        }
    }
    
    func connect(mess: String){
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = mess
        session?.begin()
    }
    
    @objc(gift:giftRejecter:)
    func gift(resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock){
        self.connect(mess: "Hold to die(gift)")
        resolveGlobal = resolve
        rejectGlobal = reject
        funcZen = 0
    }
    @objc(read:readRejecter:)
    func read(read:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(read)")
        resolveGlobal = read
        rejectGlobal = reject
        funcZen = 1
    }
    @objc(write:writeResolver:writeRejecter:)
    func write(mnemonic: String,resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(write)")
        resolveGlobal = resolve
        dataWrite = mnemonic
        rejectGlobal = reject
        funcZen = 2
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
