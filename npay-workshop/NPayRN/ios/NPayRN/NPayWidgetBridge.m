// Registers the Swift class NPayWidgetBridge with React Native, and its methods.
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(NPayWidgetBridge, NSObject)
RCT_EXTERN_METHOD(updateBalance:(NSString *)owner balancePaise:(nonnull NSNumber *)balancePaise)
RCT_EXTERN_METHOD(clear)
RCT_EXTERN_METHOD(startPaymentRequest:(NSString *)from amountPaise:(nonnull NSNumber *)amountPaise
                  seconds:(nonnull NSNumber *)seconds resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(endPaymentRequests)
@end
