#version 420

// original https://www.shadertoy.com/view/Wdjczm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535897932384626433832795

//#define u_k vec2(.001, .001)
#define in_w = 449
#define in_h = 483

void main(void)
{
    float v = 0.0;
    vec2 u_k = vec2(sin(time * 2.0) * .05 + .051, cos(time * 2.0) * .050 + .051);
    vec2 c = gl_FragCoord.xy * u_k - u_k/2.0;
    v += sin((c.x+time));
    v += sin((c.y+time)/2.0);
    v += sin((c.x+c.y+time)/2.0);
    c += u_k/2.0 * vec2(sin(time/3.0), cos(time/2.0));
    v += sin(sqrt(c.x*c.x+c.y*c.y+1.0)+time);
    v = v/2.0;
    vec3 col = vec3(1, sin(PI*v), cos(PI*v));

    // Output to screen
    glFragColor = vec4(col*.5 + .5, 1);
}

