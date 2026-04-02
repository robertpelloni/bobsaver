#version 420

// original https://www.shadertoy.com/view/NdSSW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 coord = gl_FragCoord.xy/2.0;
       float t = time;
    float x = float(coord.x)+64.0*sin((coord.x+coord.y)/60.0);
    float y = float(coord.y)+64.0*cos((coord.x-coord.y)/60.0);
    float r = float(x*x*t + y*y*t);
    float f = abs(r);
    int a = int(floor(f*pow(16.0, 6.0-ceil(log2(r)/4.0))));
    int A = a;
    glFragColor = vec4(
        sin(y/64.0),
        sin(y/32.0),
        sin(y/16.0),
        1.0
    );
    glFragColor.x+=(tan((degrees(atan(x, y))*1.0-t*2.0)))/4.0;
    glFragColor.y+=(tan((degrees(atan(x, y))*1.0-t*2.0)))/4.0;
    glFragColor.z+=(tan((degrees(atan(x, y))*1.0-t*2.0)))/4.0;
}
