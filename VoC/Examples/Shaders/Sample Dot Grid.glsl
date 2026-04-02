#version 420

// original https://www.shadertoy.com/view/wdsXR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    vec2 p = gl_FragCoord.xy  + mouse*resolution.xy.xy + time ;    
    p.y += time * 20.;
    float s = 50.;
    float k = (cos(2.*time+uv.x*uv.y*4.)+1.);
    p.y += k*step(s,mod(p.x,s*2.))*s*.5;
    p.x += k*step(s,mod(p.y,s*2.))*s*.4+30.;
    float d = length(mod(p,s)-0.5*s);    
    float points = smoothstep(d,d*.8,3.);
    glFragColor = vec4(.2+points);  
}
