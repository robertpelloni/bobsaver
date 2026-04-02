#version 420

// original https://www.shadertoy.com/view/3tScDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y*.6;
        
    float dp = dot(uv*fract(time/100.),uv);
     uv /= dp;
     uv.x=sin(uv.x*fract(time/50.)-1.5);
    uv *= .5;
    float a = atan(uv.y,uv.x);
    float t = time*.3;
    float r2 = max( .0,  abs(sin(t*.5))*6. - length(uv) );
    t += r2 * r2 *cos(r2*fract(time/100.)+t )+a *1.;        
    uv *= mat2( cos(t*fract(time/100.)), sin(t), cos(t), cos(t) );
    vec3 col = .1 + cos(uv.y *(cos(t)*2.+0.5) +t) *sin(time+uv.yxy*fract(time/100.));    
    glFragColor = vec4(col,1.0);
}
