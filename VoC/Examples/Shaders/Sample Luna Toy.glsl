#version 420

// original https://www.shadertoy.com/view/7sfSz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by Tim Rowetts youtube channel :)
// https://www.youtube.com/watch?v=Mx7xusheSN0

#define PI 3.141592
#define ROLLSPEED 0.2
#define STRIPES 24.
#define RADIUS STRIPES/5.

// True pixelwidth for antialiasing. Thank you Fabrice Neyret!
#define PW STRIPES/resolution.y 

float horizontalStripes(in vec2 uv)
{
    return smoothstep(-PW,PW, abs(fract(uv.y)-.5) - .25);
}

mat2 rotate2d(float angle)
{
    return mat2 (cos(angle), -sin(angle), sin(angle), cos(angle)) ;
}

float maskCircle(in vec2 uv, float radius)
{
    return smoothstep(radius-PW, radius+PW, length(uv));
}

vec2 roll(float dist, vec2 uv)
{
    float t = time * ROLLSPEED;
    uv.x += dist * RADIUS * cos(t);
    uv *= -rotate2d(dist * -cos(t));
    return uv;
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy - .5* resolution.xy) / resolution. y;
    uv *= STRIPES;
    vec2 lightRoller =  roll(PI, uv + vec2(0.,(STRIPES/4.)));
    vec2 darkRoller =   roll(-PI, uv - vec2(0., -.5+(STRIPES/4.)));
    float lightRollerColor = horizontalStripes(lightRoller) * (1. - maskCircle(lightRoller, RADIUS));
    float darkRollerColor =  horizontalStripes(darkRoller) * (1. - maskCircle(darkRoller, RADIUS));
    glFragColor = vec4(horizontalStripes(uv) + lightRollerColor - darkRollerColor);
}
