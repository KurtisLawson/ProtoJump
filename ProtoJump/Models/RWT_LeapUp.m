//
//  RWT_LeapUp.m
//  ProtoJump
//
//  Created by Kurtis Lawson on 2021-04-20.
//

#import "RWT_LeapUp.h"

@implementation RWT_LeapUp

-(instancetype) initWithShader:(RWTBaseEffect *)shader {
    if ((self = [super initWithName:"obj_leap-up" shader:shader vertices:(RWTVertex*) obj_LeapUp_Cube_002_Material_Vertices vertexCount:sizeof(obj_LeapUp_Cube_002_Material_Vertices) / sizeof(obj_LeapUp_Cube_002_Material_Vertices[0])])) {
        
        [self loadTexture:@"ProtoTexture.png"];
        
        self.scale = 0.5f;
    }
    
    return self;
}

@end
