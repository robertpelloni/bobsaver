#version 420

// original https://www.shadertoy.com/view/3dj3Wc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define HALF_PI 1.57079632675
#define TWO_PI 6.283185307

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

mat2 rotate(float angle)
{
    return mat2( cos(angle),-sin(angle),sin(angle),cos(angle) );
}

vec2 center(vec2 st)
{
    float aspect = resolution.x/resolution.y;
    st.x = st.x * aspect - aspect * 0.5 + 0.5;
    return st;
}

void main(void)
{
    // space.xy;
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st = center( st );
    st *= 2.0;
    st.y -= .1;

    // timing
    float seconds = 1.0;
    float t = fract(time/seconds);

    // sdf
    vec2 pos = vec2( 1.0,1.0 );
        pos = st-pos;
        pos.x *= .7;
        pos += pos*2.5*abs(sin(t));

    float r = length(pos)-.1;
    float a = abs(atan(pos.x*1.7,pos.y));// + PI;
    float g = st.y*st.x;
    float c = 1.0-smoothstep(0.0,0.02,r-a*.1);
    // color
    vec3 color = vec3(1.0, 1.0, 1.0);
        color = mix(color,vec3(1.0, 0.0, 0.0),c);
        color += vec3(1.0, 0.0, 0.298) *g*c;

    glFragColor = vec4(color, 1.0);
}
