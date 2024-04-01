import Foundation
import CoreNFC
import CryptoSwift
import CommonCrypto

@objc(Nfc)
@available(iOS 13.0, *)
class Nfc: NSObject, NFCNDEFReaderSessionDelegate{
    var session: NFCNDEFReaderSession?
    var dataWrite: NFCNDEFMessage?
    var resolveGlobal: RCTPromiseResolveBlock?
    let prefix:[UInt8] = [
        83,  97, 108, 116,
       101, 100,  95,  95,
          150, 22, 82, 143,
          156,  7,  2, 110
     ]
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        do{
                    print("messages", "error")
                    print("test")
            let datatest = "delay card fiction vacant athlete buyer tower cinnamon april bus jacket enforce"
            let pass = "1234123412341234"
            
            
                    let test1 = self.encrypt(data: datatest, key: pass)
                    print("test",test1)
                    let test2 = self.decrypt(encrypted: test1, key: pass)
                    print("test",test2)
                    print("test end")
        } catch{
            
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("messages",messages)
    }
    
    
    func encrypt(data: String, key:String) -> String {
        do {
            let keydata = try PKCS5.PBKDF2(password: key.bytes, salt: "salt".bytes, iterations: 1, keyLength: 32, variant: .md5).calculate()
            let iv = AES.randomIV(AES.blockSize)
            let aes = try! AES(key: keydata, blockMode: CBC(iv: iv), padding: .pkcs7)
            
            let ciphertext = try aes.encrypt(data.bytes)
            print("datatat",ciphertext)
            
            return (prefix+ciphertext).toBase64()
        } catch {
            return "false"
        }
    }
    
    func decrypt(encrypted: String, key:String) -> String {
        do {
//            let iv = String(decoding: AES.randomIV(AES.blockSize), as: UTF8.self)
            let aes = try AES(key: key, iv:  "drowssapdrowssap") // aes128
            let ciphertext = try aes.decrypt([UInt8](base64: encrypted))
            return String(decoding: ciphertext, as: UTF8.self)
        } catch {
            return "false"
        }
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
            tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                session.alertMessage = "read okla"
                if error != nil {
                   
                }
                else {
                    session.restartPolling()
                }
                session.invalidate()
                let data = [String(decoding: (message?.records[0].payload)!, as: UTF8.self),String(decoding: (message?.records[1].payload)!, as: UTF8.self)]
                self.resolveGlobal!(data)
            })
        }
    }
    
    func writeZen(_ session: NFCNDEFReaderSession, didDetect tag: NFCNDEFTag, didDetect data: NFCNDEFMessage){
        session.connect(to: tag){ (error: Error?) in
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
    
    func readerSession(_ session: NFCNDEFReaderSession,didDetect tags: [NFCNDEFTag]){
        let tag = tags.first!
        print("tags",tag)
        let dataTag = NFCNDEFPayload(format: NFCTypeNameFormat.media,
                                     type: "text/plain".data(using: .utf8)!,
                                     identifier: Data.init(count: 0),
                                     payload: "nam thang manh thuong quan (nami)".data(using: .utf8)!)
        let ndefMessage = NFCNDEFMessage(records: [dataTag,dataTag,dataTag])
        
        self.readZen(session,didDetect: tag)
        
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
    @objc(write:withResolver:withRejecter:)
    func write(data: Array<Double>,resolve:@escaping RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        self.connect(mess: "Hold to die(write)")
        resolveGlobal = resolve
    }
}
