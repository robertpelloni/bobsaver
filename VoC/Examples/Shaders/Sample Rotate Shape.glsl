#version 420

// original https://www.shadertoy.com/view/wtfSRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotateCW(vec2 p, float a)
{
    mat2 m = mat2(cos(a), -sin(a), sin(a), cos(a));
    return m*p;
}

float shape(float x, float y)
{
    float r = sqrt(x*x + y*y);
    return r - 1.0 + sin(3.0 * atan(y,x) + 2.0 * r*r) / 2.0;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv = uv*5.5+vec2(-2.5,-2.5);
    vec2 shp = rotateCW(uv, 10.0*time);
    // Output to screen
    glFragColor = vec4( shape(shp.x, shp.y), shape(shp.x, shp.y), shape(shp.x, shp.y),1.0);
}
