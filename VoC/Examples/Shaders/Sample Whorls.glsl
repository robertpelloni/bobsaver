#version 420

// original https://www.shadertoy.com/view/tllSR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (c) 2019, Chris Hodapp

#define PI 3.14159265358979

const float d = 1.0;

void main(void)
{
    
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec2 st2 = st - vec2(0.320,0.380);
    st -= vec2(0.670,0.620);
    st.x *= resolution.x/resolution.y;
    st2.x *= resolution.x/resolution.y;
    
    float r = sqrt(st.x*st.x + st.y*st.y);
    float th = atan(st.y, st.x);
    
    float r2 = sqrt(st2.x*st2.x + st2.y*st2.y);
    float th2 = atan(st2.y, st2.x);
  
    float th_in = th - 2.0 / (r + 0.1) + th2 - 2.0 / (r2 + 0.1) + 0.4*cos(r*100.0 + time*4.0) - 0.4*cos(r2*100.0 + time*3.0) + time*1.2;
    
    float g = smoothstep(0.00, d, mod(th_in, PI*2.0)) - smoothstep(d, 2.0*d, mod(th_in, PI*2.0));
    
    vec3 color = vec3(g);
    //color = vec3(st.x,st.y,abs(sin(u_time)));

    glFragColor = vec4(color,1.0);
}
