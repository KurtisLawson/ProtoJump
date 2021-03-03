//
//  Obstacle.h
//  ProtoJump
//
//  Created by Houman on 2021-03-02.
//

#ifndef Obstacle_h
#define Obstacle_h
#include <time.h>
#include <stdlib.h>

#define OBSTACLE_POS_X         900
#define OBSTACLE_MAX_POS_Y     400
#define OBSTACLE_MIN_POS_Y     200
#define OBSTACLE_MAX_WIDTH     100.0f
#define OBSTACLE_MIN_WIDTH     50.0f
#define OBSTACLE_MAX_HEIGHT    400.0f
#define OBSTACLE_MIN_HEIGHT    100.0f

struct Obstacle
{
    float red, green, blue, width, height;
    int posY;
    Obstacle()
    {
        srand(time(0));
        red = green = blue = 1;
        width = (rand() / (OBSTACLE_MAX_WIDTH + 1) + OBSTACLE_MIN_WIDTH);
        height = (rand() / (OBSTACLE_MAX_HEIGHT + 1) + OBSTACLE_MIN_HEIGHT);
        posY = rand() / (OBSTACLE_MAX_POS_Y + 1) + OBSTACLE_MIN_POS_Y;
    }
};

#endif /* Obstacle_h */
