#version 420

// original https://www.shadertoy.com/view/MscSDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = 3.141592;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    float aspect = resolution.x/resolution.y;
    uv.x *= aspect;
    
    
    vec2 pos = vec2(0.0, 0.0);
        
    float dist = length(uv - pos);// * sin(3.141592 * time);
    
    float time = time;
    
    float rippleRadius = time;
    
    float diff = rippleRadius - dist;
    
    float func = sin(pi * diff);
    
    uv += uv * func * 0.1;
    
    
    
    //uv *= vec2(sin(time), cos(time));
    
    float stripes = 10.0;
    float thickness = 10.0;
    float sharpness = 2.0;
    vec2 a = sin(stripes * 0.5 * pi * uv - pi/2.0);
    vec2 b = abs(a);
    
    vec3 color = vec3(0.0);
    color += 1.0 * exp(-thickness * b.x * (0.8 + 0.5 * sin(pi * time)));
    color += 1.0 * exp(-thickness * b.y);
    color += 0.5 * exp(-(thickness/4.0) * sin(b.x));
    color += 0.5 * exp(-(thickness/3.0) * b.y);
    
    float ddd = exp(-5.5 * clamp(pow(dist, 3.0), 0.0, 1.0));
    
    vec3 t = vec3(uv.x * 0.5+0.5*sin(time), uv.y * 0.5+0.5*cos(time), pow(cos(time), 4.0)) + 0.5;
    
    glFragColor = vec4(color * t * ddd, 0.0);
    //glFragColor = vec4(ddd);
}
