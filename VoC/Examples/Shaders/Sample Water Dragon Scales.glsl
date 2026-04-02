#version 420

// original https://www.shadertoy.com/view/WsdGDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Water Dragon Scales
//classic rand function
#define R(a) fract(sin(dot(a,vec2(12.9898,78.233)))*43758.5453)
const float S=sqrt(2.)/2.;
void main(void) {
    vec2 U = gl_FragCoord.xy;
    vec2 R=resolution.xy,
         p=(U+U-R)/R.y,
         q=6.*p*mat2(S,S,-S,S),
         r=fract(q)+vec2(R(U)-.5)/25.,
         d=floor(q)/2.;
    float h=R(d);
    vec3 c=normalize(vec3(0.,h,1.));
    float f=.2*float(r.x>r.y)+.8;
    float wv=.5*sin(3.*time+d.x+d.y);
    float sd=min(.5*h+3.7+wv-2.*max(r.x,r.y)-1.*(r.x+r.y),1.);
    glFragColor=vec4(sd*f*(c-.2*wv),1.);
}
