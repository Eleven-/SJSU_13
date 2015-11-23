//
//  helpers.c
//
//  Created by 悠二 on 11/22/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

#include "helpers.h"

const char* convertUInt16_toCharArray(uint16_t i) {
    
    char firstByte = i >> 8;
    char secondByte = i;
    const char arr[2] = {firstByte, secondByte};
    return arr;
}