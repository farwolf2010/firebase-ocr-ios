//
//  firebaseOcr.m
//  AFNetworking
//
//  Created by 郑江荣 on 2019/5/10.
//

#import "firebaseOcr.h"
#import "Firebase.h"
#import <WeexSDK/WXSDKEngine.h>
#import "farwolf_weex.h"
WX_PLUGIN_Entry(firebaseOcr)
@implementation firebaseOcr
-(void)initEntry:(NSMutableDictionary*)lanchOption
{
        [FIRApp configure];
}

@end
