#version 420

// original https://www.shadertoy.com/view/WlsXWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A stylized variation of the octopus from
// sben "Illustrated Equations"
// https://www.shadertoy.com/view/MtBGDW

float octopus(vec2 p, float t){
    float ret = (p.y+length(p*p.x)-cos(t+p.y));
    ret = (p.y+length(p*ret)-cos(t+p.y));
    ret = (p.y+length(p*ret)-cos(t+p.y));
    ret *= ret*.1;
    return ret;
}
float dtoa(float d, float amount){
    return 1. / clamp(d*amount, 1., amount);
}
float rand(float n){
     return fract(cos(n*89.42)*343.42);
}
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 P ) need changing to glFragColor and gl_FragCoord
{
    vec4 O = glFragColor;
    vec2 P = gl_FragCoord.xy;

    vec2 V = P/resolution.x-.5;
    V.y += .1;
    float t = time;
    float d = octopus(V*15., t);
    d -= .1;
    float a = dtoa(d, 6. + rand(V.y)*2. + rand(V.x)*1.2);
    float a2 = dtoa(-d, 15. + rand(V.y)*8. + rand(V.x)*4.);

    O = mix(vec4(.95,.9,.7,0), vec4(.5,.1,.1,0), vec4(a));
    O *= a2;

    vec2 N = P/resolution.xy-.5;
    O += (rand(N*time)-.5)*.05;
    O *= 1.-smoothstep(0.,.3,abs(N.x));
    O *= 1.-smoothstep(0.,.7,abs(N.y));
    O = pow(O,vec4(.7));
    O.a = 1.;

    glFragColor = O;
}
