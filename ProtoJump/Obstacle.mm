//
//  Obstacle.m
//  ProtoJump
//
//  Created by Houman on 2021-03-02.
//

#include "Obstacle.h"

@implementation Obstacle

@synthesize red, green, blue;
@synthesize width, height, posY;

-(instancetype)init {
    self = [super init];
    if(self){
        red = green = blue = 1;

        self.width = arc4random_uniform(OBSTACLE_MAX_WIDTH - OBSTACLE_MIN_WIDTH + 1) + OBSTACLE_MIN_WIDTH;
        self.height = arc4random_uniform(OBSTACLE_MAX_HEIGHT - OBSTACLE_MIN_HEIGHT + 1) + OBSTACLE_MIN_HEIGHT;
        self.posY = arc4random_uniform(OBSTACLE_MAX_POS_Y - OBSTACLE_MIN_POS_Y + 1) + OBSTACLE_MIN_POS_Y;
    }
    return self;
}

-(void)dealloc {
    
}

@end
