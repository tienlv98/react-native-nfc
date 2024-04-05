#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Nfc, NSObject)

RCT_EXTERN_METHOD(gift:(RCTPromiseResolveBlock)resolve
                  giftRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(read:(RCTPromiseResolveBlock)resolve
                  readRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(write:(NSString)data
                  writeResolver:(RCTPromiseResolveBlock)resolve
                  writeRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(initNfc:(RCTPromiseResolveBlock)resolve
                  initRejecter:(RCTPromiseRejectBlock)reject)



+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
