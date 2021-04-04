//
//  Player.mm
//  ProtoJump
//
//  Created by Henry Zhang on 2021-04-03.
//

#include "Player.h"

typedef enum {
    grounded,
    leftCollision,
    rightCollision,
    topCollision
} PlayerState;

@implementation Player

@synthesize posX, posY;


-(instancetype)init {
    self = [super init];
    if(self){
        
    }
    return self;
}

-(void) updatePos:(float)positionX :(float)positionY{
    posX = positionX;
    posY = positionY;
}

-(void) dealloc{
    
}

@end

