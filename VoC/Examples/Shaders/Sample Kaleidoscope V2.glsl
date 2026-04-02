#version 420

// original https://www.shadertoy.com/view/WlSGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(float n){return fract(sin(n) * (1.+mouse.x*resolution.x + mouse.y*resolution.y/10000.));}

float noise(float p){
    float f = floor(p);
    return mix(rand(f), rand(f + 1.0), fract(p));
}
    

void main(void)
{
    vec2 p = gl_FragCoord.xy; 
    p = (p + p - resolution.xy) / resolution.y;
    vec2 m = vec2(-time/2. , time/3.);
    vec2 noised = vec2(noise(m.x), noise(m.y))/2.;
    for(int i = 0; i < 11; i++)
        p = abs(p) / dot(p,p) - noised-mouse*resolution.xy.xy/resolution.xy*0.5;
    
    glFragColor = vec4(noise(p.x)*p.y, noise(p.y)*p.x, noise(p.x+p.y),1.);
         
}
