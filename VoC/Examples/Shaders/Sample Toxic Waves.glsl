#version 420

// original https://www.shadertoy.com/view/WdSXWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIZE 20.

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float rand(vec2 co) { 
    return fract(sin(dot(co.xy , vec2(12.9898, 78.233))) * 43758.5453);
} 

void main(void)
{    
    vec2 uv = gl_FragCoord.xy/resolution.xy;       
        
    uv.y += sin(uv.x*50. + time*10.)*0.025;
    uv.y += sin(uv.x*5. + time*4.)*0.05;
    
    vec2 ouv=uv;
    uv.y = floor(uv.y*SIZE)/SIZE;        
    uv.x = 0.;
    float d1 = rand(uv);
    float d2 = rand(uv + 1.);
    float d3 = rand(uv + 2.);   
           
    vec3 col = vec3(d1, d2, d3);
    
    vec3 hsv = rgb2hsv(col);
    hsv.x += time*(0.1) + uv.y;
    hsv.y = 1.;
    hsv.z = (sin(ouv.x*50. + time*10. + 3.1415)*0.5+0.5)*0.15+0.85;
    
    col = hsv2rgb(hsv);
    
    // Shadows
    float colMask = smoothstep(0.0, 0.75, fract(ouv.y * SIZE));   
    col += (colMask*0.5)-0.5;
    colMask = 1. - smoothstep(0.75, 1.0, fract(ouv.y * SIZE)); 
    col *= colMask;
    
    glFragColor = vec4(col,1.0);
}
