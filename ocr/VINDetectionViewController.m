//
//  VINDetectionViewController.m
//  TextDetection-VIN
//
//  Created by Mac on 2019/3/14.
//  Copyright © 2019 🚗. All rights reserved.
//

#import "VINDetectionViewController.h"
#import "Firebase.h"

#import <AVFoundation/AVFoundation.h>
#import "Weex.h"

@interface VINDetectionViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    UILabel *textLabel;
    AVCaptureDevice *device;
    NSString *recognizedText;
    BOOL isFocus;
    BOOL isInference;
    FIRVisionTextRecognizer *textRecognizer;
}
//@property(nonatomic,strong)  WXFOcrScanner *scanner;
@property (nonatomic, assign) CGFloat m_width; //扫描框宽度
@property (nonatomic, assign) CGFloat m_higth; //扫描框高度
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@end

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define m_scanViewY  150.0
#define m_scale [UIScreen mainScreen].scale

@implementation VINDetectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"扫一扫";
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBar.translucent = NO;
    
    //给个默认值
    self.m_width = (SCREEN_WIDTH - 40);
    self.m_higth = 80.0;
    recognizedText = @"";
    
    //初始化识别器
    FIRVision *vision = [FIRVision vision];
    //这里仅仅使用离线识别功能。‼️如果要想使用在线识别，请到Firebase官网注册APP，并购买相关服务‼️
    textRecognizer = [vision onDeviceTextRecognizer];
    
    //初始化摄像头
    [self initAVCaptureSession];
    self.isScan=true;
    
    
}



- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    NSError *error;
    
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
    //输出流
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary
                                   dictionaryWithObject:value forKey:key];
    self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureVideoDataOutput setVideoSettings:videoSettings];
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [self.captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.captureVideoDataOutput]) {
        [self.session addOutput:self.captureVideoDataOutput];
    }
    
    
    //输出照片铺满屏幕
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationPortrait) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    else {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    }
    
    self.previewLayer.frame =self.view.frame;
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
  
    //对焦
    int flags =NSKeyValueObservingOptionNew;
    [device addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
}

- (void)initScanView
{
    // 中间空心洞的区域
    CGRect cutRect = CGRectMake((SCREEN_WIDTH - _m_width)/2.0,m_scanViewY, _m_width, _m_higth);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0,0, SCREEN_WIDTH,SCREEN_HEIGHT)];
    // 挖空心洞 显示区域
    UIBezierPath *cutRectPath = [UIBezierPath bezierPathWithRect:cutRect];
    
    //将circlePath添加到path上
    [path appendPath:cutRectPath];
    path.usesEvenOddFillRule = YES;
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.opacity = 0.6;//透明度
    fillLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:fillLayer];
    
    // 边界校准线
    CGFloat lineWidth = 2;
    CGFloat lineLength = 20;
    UIBezierPath *linePath = [UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                         cutRect.origin.y - lineWidth,
                                                                         lineLength,
                                                                         lineWidth)];
    //追加路径
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width - lineLength + lineWidth,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineLength,
                                                                     lineWidth)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width ,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height - lineLength + lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height,
                                                                     lineLength,
                                                                     lineWidth)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width,
                                                                     cutRect.origin.y + cutRect.size.height - lineLength + lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width - lineLength + lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height,
                                                                     lineLength,
                                                                     lineWidth)]];
    
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.path = linePath.CGPath;// 从贝塞尔曲线获取到形状
    pathLayer.fillColor = [UIColor colorWithRed:0. green:0.655 blue:0.905 alpha:1.0].CGColor; // 闭环填充的颜色
    [self.view.layer addSublayer:pathLayer];
    
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, m_scanViewY - 40, SCREEN_WIDTH, 25)];
    [self.view addSubview:tipLabel];
    tipLabel.text = @"请对准VIN码进行扫描";
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.textColor = [UIColor whiteColor];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        isFocus = adjustingFocus;
        NSLog(@"Is adjusting focus? %@", adjustingFocus ?@"YES":@"NO");
    }
}


//-(UIImage*)getSubImage:(CGRect)rect
- (CMSampleBufferRef)cropSampleBufferByHardware:(CMSampleBufferRef)buffer rect:(CGRect)rect {
    // a CMSampleBuffer's CVImageBuffer of media data.
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);//表示开始操作数据
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    //图像宽度（像素）
    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    //图像高度（像素）
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    size_t pixelWidth =1920;
//    size_t pixelHeight =1080;
    CGFloat g_width_size=rect.size.width;
    CGFloat g_height_size=rect.size.height;
    CGFloat swidth= [UIApplication sharedApplication].keyWindow.frame.size.width;
    CGFloat sheight= [UIApplication sharedApplication].keyWindow.frame.size.height;
    CGFloat rate= rect.size.width/swidth;
     CGFloat yrate= rect.origin.y/sheight;
      CGFloat xrate= rect.origin.x/swidth;
    CGFloat trate= swidth/pixelWidth;

    CGFloat rrate= g_height_size/g_width_size;
    g_width_size=pixelWidth*rate;
    g_height_size=g_width_size*rrate;
    
    CGFloat _cropX=pixelHeight*xrate;
    CGFloat _cropY=pixelWidth*yrate;
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
    CGRect           cropRect    = CGRectMake(_cropY, _cropX, g_height_size,g_width_size );
//      CGRect           cropRect    = CGRectMake(100, 20, g_height_size,g_width_size );
    //                cropRect  =rect;
    //        log4cplus_debug("Crop", "dropRect x: %f - y : %f - width : %zu - height : %zu", cropViewX, cropViewY, width, height);
    
    /*
     First, to render to a texture, you need an image that is compatible with the OpenGL texture cache. Images that were created with the camera API are already compatible and you can immediately map them for inputs. Suppose you want to create an image to render on and later read out for some other processing though. You have to have create the image with a special property. The attributes for the image must have kCVPixelBufferIOSurfacePropertiesKey as one of the keys to the dictionary.
     如果要进行页面渲染，需要一个和OpenGL缓冲兼容的图像。用相机API创建的图像已经兼容，您可以马上映射他们进行输入。假设你从已有画面中截取一个新的画面，用作其他处理，你必须创建一种特殊的属性用来创建图像。对于图像的属性必须有kCVPixelBufferIOSurfacePropertiesKey 作为字典的Key.因此以下步骤不可省略
     */
    
    OSStatus status;
    
    /* Only resolution has changed we need to reset pixBuffer and videoInfo so that reduce calculate count */
    static CVPixelBufferRef            pixbuffer = NULL;
    static CMVideoFormatDescriptionRef videoInfo = NULL;
    
    if (pixbuffer == NULL) {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInt:g_width_size],     kCVPixelBufferWidthKey,
                                 [NSNumber numberWithInt:g_height_size],    kCVPixelBufferHeightKey, nil];
        status = CVPixelBufferCreate(kCFAllocatorSystemDefault, g_width_size, g_height_size, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)options, &pixbuffer);
        // ensures that the CVPixelBuffer is accessible in system memory. This should only be called if the base address is going to be used and the pixel data will be accessed by the CPU
        if (status != noErr) {
            NSLog(@"Crop CVPixelBufferCreate error %d",(int)status);
            return NULL;
        }
    }
    
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
    
    //         ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeRotation(-M_PI*0.5)];
    ciImage = [ciImage imageByCroppingToRect:cropRect];
    // Ciimage get real image is not in the original point  after excute crop. So we need to pan.
    
    
    //    ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeTranslation(-_cropX, -_cropY)];
    
    static CIContext *ciContext = nil;
    if (ciContext == nil) {
        //        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        //        [options setObject:[NSNull null] forKey:kCIContextWorkingColorSpace];
        //        [options setObject:@0            forKey:kCIContextUseSoftwareRenderer];
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        ciContext = [CIContext contextWithEAGLContext:eaglContext options:nil];
    }
    [ciContext render:ciImage toCVPixelBuffer:pixbuffer];
    //    [ciContext render:ciImage toCVPixelBuffer:pixbuffer bounds:cropRect colorSpace:nil];
    
    CMSampleTimingInfo sampleTime = {
        .duration               = CMSampleBufferGetDuration(buffer),
        .presentationTimeStamp  = CMSampleBufferGetPresentationTimeStamp(buffer),
        .decodeTimeStamp        = CMSampleBufferGetDecodeTimeStamp(buffer)
    };
    
    if (videoInfo == NULL) {
        status = CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixbuffer, &videoInfo);
        if (status != 0) NSLog(@"Crop CMVideoFormatDescriptionCreateForImageBuffer error %d",(int)status);
    }
    
    CMSampleBufferRef cropBuffer;
    status = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixbuffer, true, NULL, NULL, videoInfo, &sampleTime, &cropBuffer);
    if (status != 0) NSLog(@"Crop CMSampleBufferCreateForImageBuffer error %d",(int)status);
    
    return cropBuffer;
}

   

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  
    if( self.scanArea!=nil&&sampleBuffer!=nil)
    {
        if(_scanFrame.size.width==0){
            dispatch_async(dispatch_get_main_queue(), ^{
                _scanFrame=self.scanArea.view.frame;
            });
            return;
        }
      
         sampleBuffer=[self cropSampleBufferByHardware:sampleBuffer rect:_scanFrame];
    }
   
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    if (!isFocus && !isInference&&sampleBuffer!=nil ) {
        isInference = YES;
        
        // Calculate the image orientation
        FIRVisionDetectorImageOrientation orientation;
        
        //指定使用后置摄像头
        AVCaptureDevicePosition devicePosition = AVCaptureDevicePositionBack;
        
        //校准图像方向
        UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationLeftTop;
                } else {
                    orientation = FIRVisionDetectorImageOrientationRightTop;
                }
                break;
            case UIDeviceOrientationLandscapeLeft:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationBottomLeft;
                } else {
                    orientation = FIRVisionDetectorImageOrientationTopLeft;
                }
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationRightBottom;
                } else {
                    orientation = FIRVisionDetectorImageOrientationLeftBottom;
                }
                break;
            case UIDeviceOrientationLandscapeRight:
                if (devicePosition == AVCaptureDevicePositionFront) {
                    orientation = FIRVisionDetectorImageOrientationTopRight;
                } else {
                    orientation = FIRVisionDetectorImageOrientationBottomRight;
                }
                break;
            default:
                orientation = FIRVisionDetectorImageOrientationTopLeft;
                break;
        }
        
        FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
        metadata.orientation = orientation;
        
        //这里不仅可以使用buffer初始化，也可以使用 image 进行初始化
        FIRVisionImage *image = [[FIRVisionImage alloc] initWithBuffer:sampleBuffer];
//                FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:timage];
        image.metadata = metadata;
        
        //开始识别
        [textRecognizer processImage:image
                          completion:^(FIRVisionText *_Nullable result,
                                       NSError *_Nullable error) {
                              if (error == nil && result != nil) {
                                  if(!self.isScan){
                                      return;
                                  } //识别结果会包很多层：FIRVisionText——>FIRVisionTextBlock->FIRVisionTextLine->FIRVisionTextElement
                                  for (FIRVisionTextBlock *block in result.blocks) {
                                      for (FIRVisionTextLine *line in block.lines) {
                                          for (FIRVisionTextElement *element in line.elements) {
                                              NSString *elementText = element.text;
                                              NSLog(elementText);
                                              //识别17位的VIN码
//                                              if (elementText.length == 17) {
                                                  //正则表达式，排除特殊字符
                                                  NSString *regex = @"^(13[0-9]|14[579]|15[0-3,5-9]|16[6]|17[0135678]|18[0-9]|19[89])\\d{8}$";
                                                  regex=self.regex;
                                                  //                                                  NSString *regex = @"[ABCDEFGHJKLMNPRSTUVWXYZ1234567890]{17}";
                                                  NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                                                  //识别成功
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  if(_scanner!=nil)
                                                      [_scanner fireEvent:@"scan" params:@{@"data":elementText}];
                                              });
                                             
                                              
                                              

                                          }
                                      }
                                  }
                              }
                              //延迟100毫秒再继续识别下一次，降低CPU功耗，省电‼️
                              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                                  //继续识别
                                  self->isInference = NO;
                              });
                          }];
    }
}


-(void)stop{
    self.isScan=false;
//       [self.session stopRunning];
}

-(void)start{
    self.isScan=true;
    //       [self.session stopRunning];
}

-(BOOL)regexTarget:(NSString*)pattern str:(NSString*)str{
    NSString *matchStr =str;
//    NSString *pattern = @"\t\n";
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSArray *matchs = [regExp matchesInString:matchStr options:0 range:NSMakeRange(0, matchStr.length)];
    return matchs.count>0;
//    NSLog(@"匹配个数:%zd",matchs.count);//匹配个数:1
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        [self.session stopRunning];
    }

    [device removeObserver:self forKeyPath:@"adjustingFocus" context:nil];
}

/**
 完成按钮点击事件
 
 @param sender 按钮
 */
- (void)clickedFinishBtn:(UIButton *)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionComplete:)]) {
        [self.delegate recognitionComplete:textLabel.text];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
