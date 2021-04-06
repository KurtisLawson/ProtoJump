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
@synthesize isVertical;

-(instancetype)init:(bool)isVertical{
    self = [super init];
    if(self){
        R = 1;
        G = B = 0;
        self.isVertical = isVertical;
    }
    return self;
}

-(void)randomize:(float)maxSize {
    if(isVertical){
        self.width = arc4random_uniform(maxSize - HAZARD_MIN_SIZE + 1) + HAZARD_MIN_SIZE;
        self.height = HAZARD_MIN_SIZE;
    }
    else {
        self.width = HAZARD_MIN_SIZE;
        self.height = arc4random_uniform(maxSize - HAZARD_MIN_SIZE + 1) + HAZARD_MIN_SIZE;
    }
}

-(void)dealloc {
    
}

@end
