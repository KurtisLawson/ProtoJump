//
//  Hazard.m
//  ProtoJump
//
//  Created by Houman on 2021-04-04.
//

#include "Hazard.h"

@implementation Hazard

@synthesize R, G, B;
@synthesize width, height;
@synthesize posX, posY;

-(instancetype)init{
    self = [super init];
    if(self){
        R = 1;
        G = B = 0;
    }
    return self;
}

-(void)vRandomize:(float)minSize :(float)maxSize{
    self.width = HAZ_MIN_V_SIZE;
    self.height = (float)arc4random() / UINT32_MAX * (maxSize - minSize) + minSize;
}

-(void)hRandomize:(float)minSize :(float)maxSize{
    self.width = (float)arc4random() / UINT32_MAX * (maxSize - minSize) + minSize;
    self.height = HAZ_MIN_H_SIZE;
}

-(void)dealloc {
    
}

@end
