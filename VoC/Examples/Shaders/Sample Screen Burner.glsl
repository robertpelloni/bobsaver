#version 420

// original https://www.shadertoy.com/view/4dlXRH

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float r (vec2 c){
    return fract(43.*sin(c.x+7.*c.y));
}

float n (vec2 p){
    vec2 i = floor(p), w = fract(p), j = vec2(1.,0.);
    w = w*w*(3.-2.*w);
    return mix(mix(r(i), r(i+j), w.x), mix(r(i+j.yx), r(i+1.), w.x), w.y);
}

float a (vec2 p){
    float m = 0., f = 1.;
    for ( int i=0; i<9; i++ ){ m += n(f*p)/f; f*=2.; }
    return m/2.;
}

void main(void){
    float t = fract(.1*time);
    glFragColor = vec4(smoothstep(t, t+.1, a(9.*gl_FragCoord.xy / resolution.x)) * vec3(5.,2.,1.), 1.);
}
