//
//  Player.mm
//  ProtoJump
//
//  Created by Henry Zhang on 2021-04-03.
//

#include "Player.h"

@implementation Player

@synthesize posX, posY, jumpTimer, initialJump;
@synthesize jumpCount;

-(instancetype)init {
    self = [super init];
    if(self){
        //Player always start out grounded
        state = grounded;
    }
    return self;
}

//Keep updating the position when the player is still alive
-(void) updatePos:(float)positionX :(float)positionY{
    posX = positionX;
    posY = positionY;
}

//Check for which location the player hits and update the state for animations etc.
//The parameters are the position and size of the obstacles
-(void) checkCollision:(float)positionX:(float)positionY:(float)width:(float)height{
    //change the enum for which side its colliding with to the enum
    //also there will be an enum that states wether the player is grounded or not being set here
    
    //If within the bounds of x of obstacles
    if(posX >= positionX - width/2 &&
        posX <= positionX + width/2){
        //Check top of obstacles
        if(posY > positionY + height/2){
            state = grounded;
            jumpCount = 0;
        }
        else if(posY < positionY - height/2){
            //Check bottom of obstacles
            state = bottomCollision;
        }
    }
    else {
        if(posX < positionX + width/2){
            //Check right of obstacles
            state = leftCollision;
            jumpCount = 0;
        } else if(posX > positionX - width/2){
            //Check left of obstacles
            state = rightCollision;
            jumpCount = 0;
        }
    }
}

-(void) dealloc{
    
}

@end

