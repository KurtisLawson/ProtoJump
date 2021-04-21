//
//  RWT_LeapUp.h
//  ProtoJump
//
//  Created by Kurtis Lawson on 2021-04-20.
//

#import "RWTModel.h"
#import "model_LeapUp.h" // Vertices from .obj

NS_ASSUME_NONNULL_BEGIN

@interface RWT_LeapUp : RWTModel

-(instancetype) initWithShader:(RWTBaseEffect *) shader;

@end

NS_ASSUME_NONNULL_END
