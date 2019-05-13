//
//  WXFOcrScanner.h
//  AFNetworking
//
//  Created by 郑江荣 on 2019/5/10.
//

#import <UIKit/UIKit.h>
#import <WeexSDK/WeexSDK.h>



@interface WXFOcrScanner : WXComponent
@property(nonatomic, strong)  WXComponent *scanArea;
@property(nonatomic, strong)  UIViewController *vc;
@property(nonatomic, strong) NSString *regex;

@end


