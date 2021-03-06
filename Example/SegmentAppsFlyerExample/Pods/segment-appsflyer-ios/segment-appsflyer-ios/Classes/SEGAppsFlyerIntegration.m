//
//  SEGAppsFlyerIntegration.m
//  AppsFlyerSegmentiOS
//
//  Created by Golan on 5/17/16.
//  Copyright © 2016 AppsFlyer. All rights reserved.
//

#import "SEGAppsFlyerIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>

@implementation SEGAppsFlyerIntegration


- (instancetype)initWithSettings:(NSDictionary *)settings {
    if (self = [super init]) {
        self.settings = settings;
        NSString *afDevKey = [self.settings objectForKey:@"devKey"];
        NSString *appleAppId = [self.settings objectForKey:@"appleAppId"];
        
        self.appsflyer = [AppsFlyerTracker sharedTracker];
        [self.appsflyer setAppsFlyerDevKey:afDevKey];
        [self.appsflyer setAppleAppID:appleAppId];
    }
    return self;
}

- (instancetype)initWithSettings:(NSDictionary *)settings withAppsflyer:(AppsFlyerTracker *)aAppsflyer {
    
    if (self = [super init]) {
        self.settings = settings;
        self.appsflyer = aAppsflyer;
    }
    return self;
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    NSMutableDictionary *afTraits = [NSMutableDictionary dictionary];
    
    if (payload.userId != nil && [payload.userId length] != 0) {
        
        if ([NSThread isMainThread]) {
            [self.appsflyer setCustomerUserID:payload.userId];
            SEGLog(@"setCustomerUserID:%@]", payload.userId);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.appsflyer setCustomerUserID:payload.userId];
                SEGLog(@"setCustomerUserID:%@]", payload.userId);
            });
        }
    }
    
    if ([payload.traits[@"currencyCode"] isKindOfClass:[NSString class]]) {
        self.appsflyer.currencyCode = payload.traits[@"currencyCode"];
        SEGLog(@"self.appsflyer.currencyCode: %@", payload.traits[@"currencyCode"]);
    }
    
    if ([payload.traits[@"email"] isKindOfClass:[NSString class]]) {
        [afTraits setObject:payload.traits[@"email"] forKey:@"email"];
    }
    
    if ([payload.traits[@"firstName"] isKindOfClass:[NSString class]]) {
        [afTraits setObject:payload.traits[@"firstName"] forKey:@"firstName"];
    }
    
    if ([payload.traits[@"lastName"] isKindOfClass:[NSString class]]) {
        [afTraits setObject:payload.traits[@"lastName"] forKey:@"lastName"];
    }
    
    if ([payload.traits[@"username"] isKindOfClass:[NSString class]]) {
        [afTraits setObject:payload.traits[@"username"] forKey:@"username"];
    }
    
    [self.appsflyer setAdditionalData:afTraits];
    
}

- (void)track:(SEGTrackPayload *)payload
{
    if (payload.properties != nil){
        SEGLog(@"trackEvent: %@", payload.properties);
    }
    
    // Extract the revenue from the properties passed in to us.
    NSNumber *revenue = [SEGAppsFlyerIntegration extractRevenue:payload.properties withKey:@"revenue"];
    if (revenue) {
        // Track purchase event.
        NSDictionary *values = @{AFEventParamRevenue : revenue, AFEventParam1 : payload.properties};
        [self.appsflyer trackEvent:AFEventPurchase withValues:values];
        
    }
    else {
        // Track the raw event.
        [self.appsflyer trackEvent:payload.event withValues:payload.properties];
    }
    
}

+ (NSDecimalNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)revenueKey
{
    id revenueProperty = dictionary[revenueKey];
    if (revenueProperty) {
        if ([revenueProperty isKindOfClass:[NSString class]]) {
            return [NSDecimalNumber decimalNumberWithString:revenueProperty];
        } else if ([revenueProperty isKindOfClass:[NSDecimalNumber class]]) {
            return revenueProperty;
        }
    }
    return nil;
}

- (void)flush
{
    SEGLog(@"flush called, nothing to do..");
}

- (void)registeredForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
     SEGLog(@"registerPushToken");
}


- (void)receivedRemoteNotification:(NSDictionary *)userInfo {
    
    [self.appsflyer handlePushNotification:userInfo];
    SEGLog(@"[self.appsflyer handlePushNotification]");
}

-(void) reset {
    SEGLog(@"reset");
}

@end
