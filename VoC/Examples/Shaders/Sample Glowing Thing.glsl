#version 420

// original https://www.shadertoy.com/view/4lB3DG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 st = vec2(0.5, 0.5) - uv;
//    st.x *= resolution.x/resolution.y;

    float v = (cos(atan(st.y,st.x) * 3.0 + sin(t * 0.1))) + (0.5 + (sin((uv.x*10.0)+(t*1.3)) * 0.4));
    float v2 = (0.7 + cos(atan(st.y,st.x) * 3.0 - t*0.2)) + (0.5 + (sin((uv.y*10.0)+(t*1.5))) * 0.5);

    vec3 color = vec3(v, sin(v * 4.0) * 0.5, sin(v * 2.0) * 0.6);
    color.r = mix(color.r,v2, 1.0);
    color.g = mix(color.g,v2, 0.5);
    color.b = mix(color.b,v2, 0.5);
    
    
    glFragColor = vec4(color,1.0);
}
