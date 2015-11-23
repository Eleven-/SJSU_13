//
//  cubesatCommand.h
//  BLE Mission-Center
//
//  Created by 悠二 on 11/3/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

#ifndef CubesatCommands_h
#define CubesatCommands_h

#define RESET                       = 0b10000000
#define TakePicture                 = 0b10010000
#define ReadJPEGFileSize            = 0b10100000
#define ReadCurrentJPEGFileContent  = 0b10110000
#define ReadPreviosJPEGFileContent  = 0b10110001
#define SetCompressionRatio_36      = 0b11000000
#define SetCompressionRatio_0       = 0b11000001
#define SetCompressionRatio_25      = 0b11000010
#define SetCompressionRatio_50      = 0b11000100
#define SetCompressionRatio_75      = 0b11001000
#define SetImageSize_320x240        = 0b11010000
#define SetImageSize_640x480        = 0b11010001
#define SetImageSize_160x120        = 0b11010010
#define EnterPowerSaving            = 0b11100000
#define ExitPowerSaving             = 0b11110000

#endif
