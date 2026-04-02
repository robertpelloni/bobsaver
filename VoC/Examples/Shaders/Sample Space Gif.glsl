#version 420

// original https://www.shadertoy.com/view/wdlGRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// idea from:
// https://boingboing.net/2018/12/20/bend-your-spacetime-continuum.html
void main(void)
{

    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    
    uv *= mat2(.707, -.707, .707, .707);
    uv *= 15.;
    
    vec2 gv = fract(uv)-.5; 
    vec2 id = floor(uv);
    
    float m = 0.;
    float t;
    for(float y=-1.; y<=1.; y++) {
        for(float x=-1.; x<=1.; x++) {
            vec2 offs = vec2(x, y);
            
            t = -time+length(id-offs)*.2;
            float r = mix(.4, 1.5, sin(t)*.5+.5);
            float c = smoothstep(r, r*.9, length(gv+offs));
            m = m*(1.-c) + c*(1.-m);
        }
    }

    glFragColor = vec4(m);
}
