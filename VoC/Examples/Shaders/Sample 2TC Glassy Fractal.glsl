#version 420

// original https://www.shadertoy.com/view/4ls3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    vec2 z = 2.*(2.*gl_FragCoord.yx-resolution.yx)/resolution.xx;
    vec2 c = vec2(.5,.15);
    
    for(float i=0.;i<99.;i++)
    {
        z = vec2(z.x*z.x-z.y*z.y,2.*z.x*z.y)+c;
        c *= exp(.01/dot(z-c,z)); 
        if(dot(z,z)>9.){glFragColor=sin(vec4(0,.2,.5,0)+(i-log2(log2(dot(z,z))))*.1);break;}
    }
}
