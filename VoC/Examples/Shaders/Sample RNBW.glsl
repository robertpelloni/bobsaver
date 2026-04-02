#version 420

// original https://www.shadertoy.com/view/3lfGWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI2 6.2831852
#define RCOS(v) cos(v)*.5+.5

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    
    float l = length(uv);
    float lg = smoothstep(.5, .4, l) - .5;
    
    float t = time*2.;
    float ofst = (uv.y*10. + sin(uv.x*10.)*.5) * lg * -1.;
    
    float r = RCOS(t + ofst);
    float g = RCOS(t+PI2*.33 + ofst);
    float b = RCOS(t+PI2*.66 + ofst);
    
    glFragColor = vec4(vec3(r, g, b) ,1.0);
}
