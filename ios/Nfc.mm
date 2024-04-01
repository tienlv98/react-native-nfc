#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Nfc, NSObject)

RCT_EXTERN_METHOD(gift:(RCTPromiseResolveBlock)resolve
                  giftRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(read:(RCTPromiseResolveBlock)resolve
                  readRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(write:(NSArray)data)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
