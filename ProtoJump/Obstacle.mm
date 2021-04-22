//
//  Obstacle.m
//  ProtoJump
//
//  Created by Houman on 2021-03-02.
//

#include "Obstacle.h"

@implementation Obstacle

@synthesize width, height;
@synthesize posX, posY;

-(instancetype)init{
    self = [super init];
    if(self){
        [self randomize];
    }
    return self;
}



-(void)randomize{
    // Randomize based on min and max constraints
    height = (float)arc4random() / UINT32_MAX * (OBSTACLE_MAX_HEIGHT - OBSTACLE_MIN_HEIGHT) + OBSTACLE_MIN_HEIGHT;
    width = (float)arc4random() / UINT32_MAX * (OBSTACLE_MAX_WIDTH - OBSTACLE_MIN_WIDTH) + OBSTACLE_MIN_WIDTH;
    posY = (float)arc4random() / UINT32_MAX * (OBSTACLE_MAX_POS_Y - OBSTACLE_MIN_POS_Y) + OBSTACLE_MIN_POS_Y;
    posX = OBSTACLE_POS_X;
}

-(void)dealloc {
    
}

@end
