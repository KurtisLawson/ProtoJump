//
//  Player.mm
//  ProtoJump
//
//  Created by Henry Zhang on 2021-04-03.
//

#include "Player.h"

//typedef enum {
//    grounded,
//    leftCollision,
//    rightCollision,
//    topCollision
//} PlayerState;

@implementation Player

@synthesize posX, posY, jumpTimer, initialJump;


-(instancetype)init {
    self = [super init];
    if(self){
        state = grounded;
    }
    return self;
}

-(void) updatePos:(float)positionX :(float)positionY{
    posX = positionX;
    posY = positionY;
}

-(void) dealloc{
    
}

-(void) checkCollision:(float)positionX:(float)positionY:(float)width:(float)height{
    
    if(posX >= positionX - width/2 &&
        posX <= positionX + width/2){

        if(posY > positionY + height/2){
            printf("Top \n");
            state = grounded;
        }
        else if(posY < positionY - height/2){
                    //change the enum for which side its colliding with to the enum
                    //also there will be an enum that states wether the player is grounded or not being set here
            printf("Bottom \n");
            state = bottomCollision;
        }
    }
    else {
        if(posX < positionX + width/2){
            printf("Left \n");
            state = leftCollision;
        } else if(posX > positionX - width/2){
            printf("Right \n");
            state = rightCollision;
        }
    }
}

@end

