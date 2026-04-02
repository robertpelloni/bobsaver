#version 420

// original https://www.shadertoy.com/view/XlXfz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Smooth Yin Yang - Copyright 2017 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

float AntiAliasAmount = 4.0;
float DotSize = 0.3;
float OutlineThickness = 0.03;

float YinYang( vec2 p, float scale )
{
       float b = AntiAliasAmount*scale/min(resolution.y,resolution.x);
    float d = DotSize;
    float o = OutlineThickness;
    
     vec2 p2;
    float h;
    float c = 1.0;
    
    // bottom
    p2 = 2.*p;
    p2.y += 1.0;
    h = sqrt(dot(p2,p2));
    if (p.x < 0.0)
       c = mix(c, 0.0, smoothstep(1.0-b,1.0+b,h));
    c = mix(0.0, c, smoothstep(d-b,d+b,h));
    
    // top
    p2 = 2.*p;
    p2.y -= 1.0;
    h = sqrt(dot(p2,p2));
    if (p.x >= 0.0)
        c = mix(0.0, c, smoothstep(1.0-b,1.0+b,h));
    c = mix(1.0, c, smoothstep(d-b,d+b,h));
    
    // outline
    h = sqrt(dot(p,p));
    c = mix(c, 0.0, smoothstep(1.0-b,1.0,h));
    c = mix(c, 0.5, smoothstep(1.0+o,1.0+o+b,h));
    
    return c;
}

void main(void)
{
    // zoom
    float z =  mix(1.1, 30.0, smoothstep(-1.0,1.0,sin(time)));
    vec2 p = z * (2.0*gl_FragCoord.xy-resolution.xy)/min(resolution.y,resolution.x);
   
    // rotate
    float theta = -0.1*time;
    float ct = cos(theta);
    float st = sin(theta);
    p *= mat2(-st, ct, ct, st);
    
    // yin yang
    float c = YinYang( p, z );
    glFragColor = vec4( c, c, c, 1.0 );
}
