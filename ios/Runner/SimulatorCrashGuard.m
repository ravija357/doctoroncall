// SimulatorCrashGuard.m
// Prevents JitsiWebRTC's enumerateDevices from crashing on iOS Simulator
// by runtime-swizzling the method to return an empty list when device
// enumeration would produce nil values (simulator has no real camera).
//
// Swizzling only activates when TARGET_OS_SIMULATOR is true.
// On physical devices this file has zero effect.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#if TARGET_OS_SIMULATOR

@interface NSObject (SimulatorCrashGuard)
@end

@implementation NSObject (SimulatorCrashGuard)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class targetClass = NSClassFromString(@"WebRTCModule");
        if (!targetClass) return;

        SEL originalSel = NSSelectorFromString(@"enumerateDevices:");
        SEL swizzledSel = @selector(sim_safeEnumerateDevices:);

        Method originalMethod = class_getInstanceMethod(targetClass, originalSel);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSel);
        if (!originalMethod || !swizzledMethod) return;

        method_exchangeImplementations(originalMethod, swizzledMethod);
        NSLog(@"[SimulatorCrashGuard] Swizzled WebRTCModule.enumerateDevices for simulator safety.");
    });
}

- (void)sim_safeEnumerateDevices:(id)callback {
    // On simulator, just return an empty device list instead of crashing
    // with null NSDictionary values when camera hardware is absent.
    @try {
        if (callback && [callback isKindOfClass:[NSArray class]]) {
            // Pass empty array to the callback
            NSArray *args = (NSArray *)callback;
            if (args.count > 0 && [args[0] isKindOfClass:[NSString class]]) {
                // Old-style callback
            }
        }
        // Invoke with empty devices array
        if ([callback respondsToSelector:@selector(call:)]) {
            [callback performSelector:@selector(call:) withObject:@[]];
        }
    } @catch (NSException *e) {
        NSLog(@"[SimulatorCrashGuard] Caught exception in enumerateDevices: %@", e);
    }
}

@end

#endif
