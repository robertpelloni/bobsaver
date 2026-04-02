#version 420

// original https://www.shadertoy.com/view/4t3GWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float v(in vec2 uv, float d, float o){
    return 1.0-smoothstep(0.0, d, distance(uv.x, 0.5 + sin(o+uv.y*3.0)*0.3));
}

vec4 b(vec2 uv, float o) {
 float d = 0.05+abs(sin(o*0.2))*0.25 * distance(uv.y+0.5, 0.0);
 return vec4(v(uv+vec2(d*0.25, 0.0), d, o), 0.0, 0.0, 1.0) +
        vec4(0.0, v(uv-vec2(0.015, 0.005), d, o), 0.0, 1.0) + 
        vec4(0.0, 0.0, v(uv-vec2(d*0.5, 0.015), d, o), 1.0);   
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.y;
    glFragColor =  b(uv, time)*0.5 + 
       b(uv, time*2.0)*0.5 + 
       b(uv+vec2(0.3, 0.0), time*3.3)*0.5;
        
     
}
