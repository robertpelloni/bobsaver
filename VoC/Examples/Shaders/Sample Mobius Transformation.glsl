#version 420

// original https://www.shadertoy.com/view/MtjBzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = (gl_FragCoord.xy-resolution.xy/2.) / resolution.y;
    p.y += 0.45;
    
    float a = cos(time);
    float b = sin(time);
    float c = -sin(time);
    float d = cos(time); // SL(2,R)
    
    float nx = p.x * a + b;
    float ny = p.y * a;
    float dx = p.x * c + d;
    float dy = p.y * c;
    float deno = dx*dx + dy*dy;
    float numex = nx * dx + ny * dy;
    float numey = ny * dx - nx * dy;
    p = vec2(numex, numey) / deno;
    
    float arg = atan(p.y,p.x);
    float len = length(p);
    vec3 hue = cos(vec3(0,1,-1)*2./3.*3.141592 + arg) * 0.5 + 0.5;
    float lum = 1.;
    lum *= pow(-cos(len * 30.) * 0.5 + 0.5, 0.1);
    lum *= pow(-cos(p.x * 30.) * 0.5 + 0.502, 0.03);
    lum *= pow(-cos(p.y * 30.) * 0.5 + 0.502, 0.03);
    vec3 col = hue * lum; 
    glFragColor = vec4(col,1.0);
}
