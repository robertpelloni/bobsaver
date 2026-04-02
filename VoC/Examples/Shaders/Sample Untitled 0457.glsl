#version 420

// original https://www.shadertoy.com/view/3stGW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec2 pol = vec2(atan(uv.x,uv.y)/6.28+.5,length(uv)); //(angle,dist)
    pol.x -= time/20.;
    pol.y += time/10.;
    
    pol.x += length(uv)/5.;
    
    vec3 col = vec3(0.);
    float b = length(uv)*1.5+.2;
    
    col.r += smoothstep(-b,b,sin((pol.y)*8.*PI));
    col.r = mix(col.r,1.-col.r,smoothstep(-b,b,sin((pol.x)*16.*PI)));
    
    pol.x += .005;
    col.g += smoothstep(-b,b,sin((pol.y)*8.*PI));
    col.g = mix(col.g,1.-col.g,smoothstep(-b,b,sin((pol.x)*16.*PI)));
    
    pol += vec2(.006,-.01);
    col.b += smoothstep(-b,b,sin((pol.y)*8.*PI));
    col.b = mix(col.b,1.-col.b,smoothstep(-b,b,sin((pol.x)*16.*PI)));
    
    glFragColor = vec4(col,1.0);
}
