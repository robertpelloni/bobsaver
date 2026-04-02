#version 420

// original https://www.shadertoy.com/view/flBSzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson

#define R resolution.xy
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define ss(a, b, t) smoothstep(a, b, t)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

void main(void) {
    float t = time*.25 - 1.5;
    
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    uv += vec2(t, t*.2 - .4);
    
    //if(mouse*resolution.xy.z > 0.)
    //    uv += m*5.;
    
    uv *= rot(3.1415/4.);
    uv = fract(uv * .35) - .5;
    uv = abs(uv);
    
    vec2 v = vec2(cos(.09), sin(.09));
    float dp = dot(uv, v);
    uv -= v*max(0., dp)*2.;
    
    float w = 0.;
    for(float i = 0.; i < 27.;i++){
        uv *= 1.23;
        uv = abs(uv);
        uv -= 0.36;
        uv -= v*min(0., dot(uv, v))*2.;
        uv.y += cos(uv.x*45.)*.007;
        w += dot(uv, uv);
    }
    
    float n = (w*12. + dp*15.);
    vec3 col = 1. - (.6 + .6*cos(vec3(.45, 0.6, .81) * n + vec3(-.6, .3, -.6)));
    
    col *= max(ss(.0, .11, abs(uv.y*.4)), .8);
    col = pow(col * 1.2, vec3(1.6));
    glFragColor = vec4(1.-exp(-col), 1.);
}
