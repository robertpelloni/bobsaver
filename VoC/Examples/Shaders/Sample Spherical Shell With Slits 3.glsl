#version 420

// original https://neort.io/art/c3aovvc3p9f8s59beu50

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define t time
#define r resolution
#define FC gl_FragCoord
#define o glFragColor

#define L length

const float PI = acos(-1.);

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

void main(void) {
    vec3 R;
    R.z+=5.;
    float d=1.,a,c=0.;
    for(float i=0.;i<99.;i++){
        if(d<1e-4)break;
        a=(acos(R.y/L(R))-sign(R.z)*acos(R.x/L(R.zx))-t)*10.;
        d=max(abs(L(R)-2.)-.01,sin(a)*.03);
        R+=vec3((FC.xy-r*.5)/r.y,-1)*d;
        c++;
    }
    if(L(R)<2.)o.rgb=hsv(a/PI/20.,1.,1.);
    else if(L(R)<2.1)o+=1.;
    o*=20./c;
    o.w=1.;
}
