//
//  Copyright © Borna Noureddin. All rights reserved.
//

#version 300 es

precision highp float;
in vec4 v_color;
out vec4 o_fragColor;

void main()
{
    o_fragColor = v_color;
}

