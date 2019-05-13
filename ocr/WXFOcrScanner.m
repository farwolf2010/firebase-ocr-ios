//
//  WXFOcrScanner.m
//  AFNetworking
//
//  Created by 郑江荣 on 2019/5/10.
//

#import "WXFOcrScanner.h"
#import "farwolf.h"
#import "Masonry.h"
#import "scanArea.h"

#import <WeexPluginLoader/WeexPluginLoader.h>
#import "VINDetectionViewController.h"


WX_PlUGIN_EXPORT_COMPONENT(firebaseOcr, WXFOcrScanner)

@implementation WXFOcrScanner
WX_EXPORT_METHOD(@selector(stop))
WX_EXPORT_METHOD(@selector(start))
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance
{
    if (self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance]) {
        self.regex=attributes[@"iosRegex"];
    }
    
    return self;
}


-(void)stop{
    [((VINDetectionViewController*)self.vc) stop];
}

-(void)start{
    [((VINDetectionViewController*)self.vc) start];
}
-(void)viewDidLoad
{
     self.vc=[VINDetectionViewController new];
    [self.view addSubview:_vc.view];
    [self.weexInstance.viewController addChildViewController:_vc];
    __weak typeof (self) weakSelf=self;
    [_vc.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.view);
    }];
    if(self.scanArea)
    [self.view bringSubviewToFront:self.scanArea.view];
    ((VINDetectionViewController*)self.vc).regex=self.regex;
       ((VINDetectionViewController*)self.vc).scanner=self;

    
//    CGRect rect=  [_layer metadataOutputRectOfInterestForRect:frame];
    //    [_output setRectOfInterest:rect];
}

-(UIView*)loadView
{
    //    UIViewController *vc= [[UIViewController alloc] init];
    //    self.host=vc;
    //    [self.weexInstance.viewController addChildViewController:self.host];
    //     [self.host didMoveToParentViewController:self.weexInstance.viewController];
    //    return vc.view;
    WXView *view=  [super loadView];;
    
    return  [UIView new];
}




-(void)insertSubview:(WXComponent *)subcomponent atIndex:(NSInteger)index{
    
    
    if([subcomponent isKindOfClass:[scanArea class]]){
        [super insertSubview:subcomponent atIndex:index];
        _scanArea=subcomponent;
        if(self.scanArea)
            [self.view bringSubviewToFront:self.scanArea.view];
//        CGRect frame= _scanArea.calculatedFrame;
           ((VINDetectionViewController*)self.vc).scanArea=subcomponent;
        int k=0;
//        [vc setScanArea:frame];
    }
//    [self.view addSubviewFull:subcomponent.view];
//    [self show];
//    [subcomponent fireEvent:@"load" params:self.weexInstance.param];
    
//    CGRect frame= subcomponent.view.frame
//    CGRect rect=  [_layer metadataOutputRectOfInterestForRect:frame];
//    [_output setRectOfInterest:rect];
}

@end
