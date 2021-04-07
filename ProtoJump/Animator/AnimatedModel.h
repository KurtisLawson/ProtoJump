//
//  AnimatedModel.h
//  ProtoJump
//
//  Created by Kurtis Lawson on 2021-04-02.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <OpenGLES/ES3/gl.h>
#import "Joint.h"

NS_ASSUME_NONNULL_BEGIN

@interface AnimatedModel : NSObject

//@property NSMutableArray *jointTransforms;

-(id) init:(GLuint)model :(GLuint)tex :(Joint *)root:(int) numJoints;

//-(void) setJointTransforms:(Joint *) headJoint;
-(void) setupVAO;

@end

NS_ASSUME_NONNULL_END
