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

-(instancetype)init {
    self = [super init];
    if(self){
        R = 1;
        G = B = 0;
    }
    return self;
}

-(void)randomize:(float)maxSize {
}

-(void)dealloc {
    
}

@end
