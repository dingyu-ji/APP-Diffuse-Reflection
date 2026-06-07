//
//  CPCLCommand.m
//  101
//
//  Created by 刘明 on 04/05/2026.
//

#import "CPCLCommand.h"

@implementation CPCLCommand {
    NSMutableData *_commandData;
    NSStringEncoding _gbEncoding;
}

- (instancetype)init {
    if (self = [super init]) {
        _commandData = [[NSMutableData alloc] init];
        // 预设 GB18030 编码，用于处理中文
        _gbEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    }
    return self;
}

// 1. 初始化：! <offset> <x-res> <y-res> <height> <qty>
-(void)addInitializePrinterwithOffset:(int)offset withHeight:(int)height withQTY:(int)qty {
    NSString *cmd = [NSString stringWithFormat:@"! %d 200 200 %d %d\r\n", offset, height, qty];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// 2. 打印并换页
-(void)addPrint {
    [_commandData appendData:[@"PRINT\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

// 3. 获取最终二进制指令
-(NSData*)getCommand {
    return _commandData;
}

// 4. 多行文本打印逻辑（核心：自动换行通常由指令集内部或手动计算实现，这里采用文本段发送）
-(void)addMultiLineWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    int currentY = y;
    int lineHeight = (font == FONT_02) ? 30 : 24; // 根据字体预估行高
    
    for (NSString *line in lines) {
        [self addText:T withFont:font withXstart:x withYstart:currentY withContent:line];
        currentY += lineHeight;
    }
}

// 5. 标准文本指令: TEXT <font> <size> <x> <y> <data>
-(void)addText:(TEXTCOMMAND)type withFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {
    NSString *cmdPrefix;
    switch (type) {
        case T90: case VT: cmdPrefix = @"TEXT90"; break;
        case T180: cmdPrefix = @"TEXT180"; break;
        case T270: cmdPrefix = @"TEXT270"; break;
        default: cmdPrefix = @"TEXT"; break;
    }
    
    // CPCL 标准格式，size 设为 0
    NSString *cmd = [NSString stringWithFormat:@"%@ %d 0 %d %d %@\r\n", cmdPrefix, font, x, y, text];
    [_commandData appendData:[cmd dataUsingEncoding:_gbEncoding]];
}

// 6. 对齐方式
-(void)addJustification:(ALIGNMENT)align {
    NSString *alignStr = @"LEFT";
    if (align == CENTER) alignStr = @"CENTER";
    if (align == RIGHT) alignStr = @"RIGHT";
    
    NSString *cmd = [NSString stringWithFormat:@"%@\r\n", alignStr];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// 7. 条码打印: BARCODE <type> <width> <ratio> <height> <x> <y> <data>
-(void)addBarcode:(COMMAND)command withType:(CPCLBARCODETYPE)type withWidth:(int)width withRatio:(BARCODERATIO)ratio withHeight:(int)height withXstart:(int)x withYstart:(int)y withString:(NSString*)text {
    NSString *cmdName = (command == VBARCODE) ? @"VBARCODE" : @"BARCODE";
    // 简化处理条码类型映射
    NSString *typeStr = @"128";
    
    NSString *cmd = [NSString stringWithFormat:@"%@ %s %d %d %d %d %d %@\r\n",
                     cmdName, [typeStr UTF8String], width, (int)ratio, height, x, y, text];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// 8. 二维码打印: BARCODE QR <x> <y> [M n] [U u]
-(void)addQrcode:(COMMAND)command withXstart:(int)x withYstart:(int)y with:(int)n with:(int)u withString:(NSString*)text {
    NSString *cmdName = (command == VBARCODE) ? @"VBARCODE" : @"BARCODE";
    NSString *cmd = [NSString stringWithFormat:@"%@ QR %d %d M %d U %d\r\n%@\r\nENDQR\r\n",
                     cmdName, x, y, n, u, text];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// 9. 字体放大
-(void)addSetmagWithWidthScale:(int)w withHeightScale:(int)h {
    NSString *cmd = [NSString stringWithFormat:@"SETMAG %d %d\r\n", w, h];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// 10. 页面宽度设置
-(void)addPagewidth:(int)width {
    NSString *cmd = [NSString stringWithFormat:@"PAGE-WIDTH %d\r\n", width];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// 11. 字体加粗
- (void)setBold:(BOOL)isBold {
    NSString *cmd = [NSString stringWithFormat:@"SETBOLD %d\r\n", isBold ? 1 : 0];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}

// --- 其余不常用函数补空，确保编译通过 ---
-(void)drawWatermarks:(TEXTCOMMAND)type withFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text withBold:(BOOL)bold withWidthScale:(int)w withHeightScale:(int)h {}
-(void)addCustomMultiLineTextWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withRowWidth:(int)width withFixHeight:(int)fixHeight withContent:(NSString*)text {}
-(void)addReverseText:(TEXTCOMMAND)type withFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {}
-(void)addMultiLineReverseTextWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {}
-(void)addCustomMultiLineReverseTextWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withRowWidth:(int)width withFixHeight:(int)fixHeight withContent:(NSString*)text {}
-(void)addBarcodeTextWithFont:(int)font withOffset:(int)offset {}
-(void)addBarcodeTextOff {}
-(void)addGraphics:(GRAPHICS)command WithXstart:(int)x withYstart:(int)y withImage:(UIImage*)img withMaxWidth:(int)maxWidth {}
-(void)addLineWithXstart:(int)x withYstart:(int)y withXend:(int)xend withYend:(int)yend withWidth:(int)width {
    NSString *cmd = [NSString stringWithFormat:@"LINE %d %d %d %d %d\r\n", x, y, xend, yend, width];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}
-(void)addBoxWithXstart:(int)x withYstart:(int)y withXend:(int)xend withYend:(int)yend withThickness:(int)thickness {
    NSString *cmd = [NSString stringWithFormat:@"BOX %d %d %d %d %d\r\n", x, y, xend, yend, thickness];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}
-(void)addInverseLineWithXstart:(int)x withYstart:(int)y withXend:(int)xend withYend:(int)yend withWidth:(int)width {}
-(void)addSpeed:(CPCLSPEED)level {
    NSString *cmd = [NSString stringWithFormat:@"SPEED %d\r\n", (int)level];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}
-(void)addBeep:(int)beep_length {
    NSString *cmd = [NSString stringWithFormat:@"BEEP %d\r\n", beep_length];
    [_commandData appendData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
}
-(void)queryPrinterStatus {}

@end
