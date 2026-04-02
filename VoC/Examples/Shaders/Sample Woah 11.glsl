#version 420

// original https://www.shadertoy.com/view/XsjSDh
// full screen then stare at center for 1 minute

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

// LICENSE: CC0
// *-SA-NC considered to be cancerous and non-free

const float PI = 3.14159;

void main(){
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    float r = length(uv);
    float a = atan(uv.y, uv.x)*10.0;
    a += time*10.0;
    a += log(r)*50.0;
    
    float g = cos(mod(a, PI)*2.0)*0.5 + 0.5;
    
    g *= smoothstep(0.0, 0.7, r);
    
    glFragColor = vec4(g);
}
