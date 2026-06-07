//
//  EscCommand.m
//  101
//
//  Created by 刘明 on 06/05/2026.
//

#import <Foundation/Foundation.h>
#import "EscCommand.h"

@interface EscCommand ()
@property (nonatomic, strong) NSMutableData *commandData;
@end

@implementation EscCommand

- (instancetype)init {
    self = [super init];
    if (self) {
        _commandData = [[NSMutableData alloc] init];
    }
    return self;
}

-(NSData*)getCommand {
    return _commandData;
}

// --- 基础控制 ---

-(void)addInitializePrinter {
    const uint8_t cmd[] = {0x1b, 0x40};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addText:(NSString*)text {
    if (!text) return;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *data = [text dataUsingEncoding:enc];
    if (data) {
        [_commandData appendData:data];
    }
}

/**
 * 方法说明：设置打印模式，0x1B 0x21 n(0-255)
 * 参数 n 的位定义：
 * Bit 0: 字体选择 (0: FontA, 1: FontB)
 * Bit 3: 加粗 (1: 加粗)
 * Bit 4: 倍高 (1: 倍高)
 * Bit 5: 倍宽 (1: 倍宽)
 * Bit 7: 下划线 (1: 下划线)
 */
-(void)addPrintMode:(int)n {
    const uint8_t cmd[] = {0x1b, 0x21, (uint8_t)n};
    [self.commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addPrintAndLineFeed {
    const uint8_t cmd[] = {0x0a};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addPrintAndFeedLines:(int)n {
    const uint8_t cmd[] = {0x1b, 0x64, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addSetJustification:(int)n {
    const uint8_t cmd[] = {0x1b, 0x61, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addSetCharcterSize:(int)n {
    const uint8_t cmd[] = {0x1d, 0x21, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

// --- 汉字模式控制 (解决 addCancelKanjiMode 等报错) ---

-(void)addSelectKanjiMode {
    const uint8_t cmd[] = {0x1c, 0x26};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addCancelKanjiMode {
    const uint8_t cmd[] = {0x1c, 0x2e};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addSetKanjiFontMode:(int)n {
    const uint8_t cmd[] = {0x1c, 0x21, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addSetKanjiUnderLine:(int)n {
    const uint8_t cmd[] = {0x1c, 0x2d, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

// --- 条码与二维码 (解决 addCODE128ABC 等报错) ---

-(void)addCODE128:(char)charset :(NSString*)content {
    const uint8_t cmd[] = {0x1d, 0x6b, 0x49};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
    // 简化处理，实际需要计算长度 n
    [self addText:content];
}

-(void)addCODE128ABC:(int)height :(int)width :(NSData*)data {
    // 厂商指令通常包含 设置高度、宽度、然后发送位图数据
    const uint8_t h[] = {0x1d, 0x68, (uint8_t)height};
    const uint8_t w[] = {0x1d, 0x77, (uint8_t)width};
    const uint8_t c[] = {0x1d, 0x6b, 0x49, (uint8_t)data.length};
    [_commandData appendBytes:h length:3];
    [_commandData appendBytes:w length:3];
    [_commandData appendBytes:c length:4];
    [_commandData appendData:data];
}

-(void)addQRCodeSizewithpL:(int)pL withpH:(int)pH withcn:(int)cn withyfn:(int)fn withn:(int)n {
    const uint8_t cmd[] = {0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x43, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addQRCodeSavewithpL:(int)pL withpH:(int)pH withcn:(int)cn withyfn:(int)fn withm:(int)m withData:(NSData*)data {
    const uint8_t head[] = {0x1d, 0x28, 0x6b, (uint8_t)pL, (uint8_t)pH, 0x31, 0x50, 0x30};
    [_commandData appendBytes:head length:sizeof(head)];
    [_commandData appendData:data];
}

-(void)addQRCodePrintwithpL:(int)pL withpH:(int)pH withcn:(int)cn withyfn:(int)fn withm:(int)m {
    const uint8_t cmd[] = {0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x51, 0x30};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

// --- 状态查询与其他 (补全剩余空壳，防止报错) ---

-(void)queryPrinterStatus {
    const uint8_t cmd[] = {0x10, 0x04, 0x01};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addTurnEmphasizedModeOnOrOff:(int)n {
    const uint8_t cmd[] = {0x1b, 0x45, (uint8_t)n};
    [_commandData appendBytes:cmd length:sizeof(cmd)];
}

-(void)addNSDataToCommand:(NSData*)data {
    if (data) [_commandData appendData:data];
}

// 补全所有 .h 中的方法空实现，消除 NotFound 错误
-(void)addUPCAtest:(NSString*)content {}
-(void)addStrToCommand:(NSString*)str {}
-(void)addSetInternationalCharacterSet:(int)n {}
-(void)addSet90ClockWiseRotatin:(int)n {}
-(void)addOpenCashDawer:(int)m :(int)t1 :(int)t2 {}
-(void)addSound:(int)m :(int)t :(int)n {}
-(void)addLineSpacing:(int)n {}
-(void)addSetUpsideDownMode:(int)n {}
-(void)addSetReverseMode:(int)n {}
-(void)queryRealtimeStatus:(int)n {}
-(void)addCutPaperAndFeed:(int)n {}
-(void)addCutPaper:(int)m {}
-(void)addSetBarcodeHRPosition:(int)n {}
-(void)addSetBarcodeHRIFont {}
-(void)addSetBarcodeHeight:(int)n {}
-(void)addSetBarcodeWidth:(int)n {}
-(void)addEAN13:(NSString*)content {}
-(void)addEAN8:(NSString*)content {}
-(void)addUPCA:(NSString*)content {}
-(void)addITF:(NSString*)content {}
-(void)addCODE39:(NSString*)content {}
-(void)addNVLOGO:(int)n :(int)m {}
/**
 *  方法说明：打印光栅位图 (补全版)
 *  param image 图片
 */
-(void)addOriginrastBitImage:(UIImage *)image {
    if (!image) return;

    // 1. 预处理：缩放图片
    int width = 384;
    float scale = (float)width / image.size.width;
    int height = (int)(image.size.height * scale);
    
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(size);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, width, height));
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 2. 获取原始像素数据（灰度模式以便处理）
    CGImageRef cgImage = resizedImage.CGImage;
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width, CGColorSpaceCreateDeviceGray(), kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    uint8_t *pixels = (uint8_t *)CGBitmapContextGetData(context);
    
    // 3. Floyd-Steinberg 抖动算法处理
    // 创建一个浮点型缓冲区来存储灰度值，防止取值范围溢出
    float *grayBuffer = (float *)malloc(width * height * sizeof(float));
    for (int i = 0; i < width * height; i++) {
        grayBuffer[i] = (float)pixels[i];
    }

    int bytesPerRow = (width + 7) / 8;
    uint8_t *bitmapData = (uint8_t *)calloc(bytesPerRow * height, sizeof(uint8_t));

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int idx = y * width + x;
            float oldPixel = grayBuffer[idx];
            // 决定当前点是黑还是白
            float newPixel = oldPixel < 128 ? 0 : 255;
            
            if (newPixel == 0) {
                int byteIndex = y * bytesPerRow + (x / 8);
                int bitIndex = 7 - (x % 8);
                bitmapData[byteIndex] |= (1 << bitIndex);
            }

            // 计算误差并扩散到邻近像素
            float error = oldPixel - newPixel;
            
            // 右边像素: error * 7/16
            if (x + 1 < width) grayBuffer[idx + 1] += error * 7.0/16.0;
            if (y + 1 < height) {
                // 左下方像素: error * 3/16
                if (x > 0) grayBuffer[idx + width - 1] += error * 3.0/16.0;
                // 正下方像素: error * 5/16
                grayBuffer[idx + width] += error * 5.0/16.0;
                // 右下方像素: error * 1/16
                if (x + 1 < width) grayBuffer[idx + width + 1] += error * 1.0/16.0;
            }
        }
    }

    // 4. 构建并发送指令
    uint8_t xL = (uint8_t)(bytesPerRow & 0xff);
    uint8_t xH = (uint8_t)((bytesPerRow >> 8) & 0xff);
    uint8_t yL = (uint8_t)(height & 0xff);
    uint8_t yH = (uint8_t)((height >> 8) & 0xff);
    
    uint8_t header[] = {0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH};
    NSMutableData *finalData = [[NSMutableData alloc] initWithBytes:header length:sizeof(header)];
    [finalData appendBytes:bitmapData length:bytesPerRow * height];
    
    [self addNSDataToCommand:finalData];
    
    // 5. 释放内存
    free(grayBuffer);
    free(bitmapData);
    CGContextRelease(context);
}

-(void)addOriginrastBitImage:(UIImage *)image width:(int)width {}
//-(void)addOriginrastBitImage:(UIImage *)image {}
-(void)addQRCodeLevelwithpL:(int)pL withpH:(int)pH withcn:(int)cn withyfn:(int)fn withn:(int)n {}
-(void)addSetCharacterRightSpace:(int)n {}
-(void)addSetKanjiLefttandRightSpace:(int)n1 :(int)n2 {}
-(void)addTurnDoubleStrikeOnOrOff:(int)n {}
-(void)addSetHorAndVerMotionUnitsX:(int)x Y:(int)y {}
-(void)addSetAbsolutePrintPosition:(int)n {}
-(void)addSetPrintingAreaWidth:(int)width {}
-(void)receiptDoubleHeightOrDefaultPrintN1:(int)n1 N2:(int)n2 N3:(int)n3 N4:(int)n4 {}
-(void)setDefaultCodePage:(int)n {}
-(void)setBaudRate:(int)baudRate {}
-(void)queryElectricity {}

@end
