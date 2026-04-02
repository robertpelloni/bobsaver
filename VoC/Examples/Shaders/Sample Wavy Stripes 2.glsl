#version 420

// original https://www.shadertoy.com/view/ctSSDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795

void main(void)
{
    vec2 center = gl_FragCoord.xy/resolution.xy - vec2(0.5, 0.5);
    
    float dist = length(center);
    float p = (atan(center.y,center.x)) / (2.0 * PI);
    float numStripes = 12.0;
        
    bool stripeA = mod(floor((p * numStripes) + (sin(dist * 10.0 + sin(time)))), 2.0) == 1.0;
    bool stripeB = mod(floor((p * numStripes) - (sin(dist * 10.0 + cos(time)))), 2.0) == 1.0;
    
    vec3 col;
    
    if (stripeA && stripeB)
    {
        col = vec3(0.4);
    }
    else if (!stripeA && stripeB)
    {
        col = vec3(0.5, 0.2, 0.1);
    }
    else if (stripeA && !stripeB)
    {
        col = vec3(0.3, 0.2, 0.1);
    }
    else
    {
        col = vec3(0.7);
    }

    glFragColor = vec4(col,1.0);
}
