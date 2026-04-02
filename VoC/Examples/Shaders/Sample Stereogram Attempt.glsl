#version 420

// original https://www.shadertoy.com/view/ldGfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://www.shadertoy.com/view/4djSRW
#define HASHSCALE1 .1031
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// http://www.techmind.org/stereo/stech.html
const float XDPI = 200.;
const float EYE_SEP = XDPI*5.5;
const float OBS_DIST = XDPI*20.;
const float REPEAT = 100.;

float repHash(vec2 coord)
{
    coord.x = mod(coord.x, REPEAT);
    return hash12(coord);
}

float depthMap(vec2 coord)
{
    vec2 v = sin(coord*0.02 + 3.*time);
    return 300.0 + 50. * v.x*v.y;
}

vec3 genColor()
{
    vec2 currCoord = gl_FragCoord.xy;
    for(int i = 0; i < 64; i++)
    {
        // http://www.techmind.org/stereo/stech.html
         float depth = depthMap(currCoord);
        float sep = EYE_SEP*depth/(depth + OBS_DIST);
        sep = floor(sep);
        if(sep < 1.0 || currCoord.x < 0.0)
            break;
        currCoord.x -= sep;
    }
    return vec3(repHash(currCoord));
}

void main(void)
{    
    vec3 col = genColor();
    glFragColor = vec4(col,1.0);
}
