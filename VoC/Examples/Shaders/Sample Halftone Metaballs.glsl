#version 420

// original https://www.shadertoy.com/view/ts3XRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Halftone Metaballs
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders" and inspiration 

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*4378.5453);
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st.x *= resolution.x/resolution.y;
    vec3 color = vec3(.0);

    // Scale
    st *= 2.;

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);

    float m =10.;

    for (int j=-1; j<=1; j++ ) {
        for (int i=-1; i<=1; i++ ) {
            vec2 neighbor = vec2(float(i),float(j));
            vec2 point = random2(i_st + neighbor);
            point = 0.5 + 0.5*sin(time + 6.2831*point);
            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);
           
            m = min(m,m*dist);
        }
    }
    
    st *= 20.;
    vec2 pt = vec2(floor(st)+0.5);
    float c = (1.0-length(st-pt))*(1.0-m*0.5);
    color = vec3(1.0-smoothstep(0.,0.075,abs(0.4-c)));

    glFragColor = vec4(color,1.0);
}

