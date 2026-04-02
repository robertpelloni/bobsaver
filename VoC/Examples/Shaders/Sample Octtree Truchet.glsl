#version 420

// original https://www.shadertoy.com/view/st3GRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// created by florian berger (flockaroo) - 2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// 3D-generalization of multi-scale-truchets (Octtree truchet)
//
// ...like Shanes 2D version (not sure, but i think he did it first in 2D)
// "Quadtree Truchet" https://www.shadertoy.com/view/4t3BW4
//
// wasnt sure if it works visually in 3D - kind of crowded, but i like it a lot...
// different regions with different truchet-scale can easily be seen.
//
// golfed it down, but i guess there's still potential...
//
// also here a (only single-scale) version on twigl in under 1 tweet:
// https://twitter.com/flockaroo/status/1454405159224754184

#define Res resolution.xy
#define ROT(v,x) v=mat2(cos(x),sin(x),-sin(x),cos(x))*v;
#define R(p) cos(((p)+(p).zxy*1.1+(p).yzx*1.3)*10.)
#define L(n,c) for(int i=0;i<n;i++){c;}
#define t time

#define dd(X,p2) \
{ \
    vec3 p=p2; \
    p+=R(p*.3)*.05; float l,d=1e3,s=2.; \
    vec3 q,r; \
    L(4,s*=.5;q=floor(p/s)*s;r=R(q);if(r.x<.5) break) \
    p=((p-q)/s-.5)*sign(r); s*=8.; \
    L(3,l=length(p.xy+.5)*s; d=min(d,length(vec2(l-(min(floor(l),s-1.)+.5),(fract(p.z*s+.5*s)-.5)))/s); p.zxy=p*vec3(-1,-1,1) ) \
    X+=(d*s/8.-2e-3)*.6; \
}

void main(void)
{
    vec4 C = vec4(0.0);
	vec3 p,d=vec3((gl_FragCoord.xy-Res*.5)/Res.x*2.,-.7);
    ROT(d.yz,t*.2);
    ROT(d.xy,t*.07);
    p=vec3(7,2,1)*t/1e2;
    float x=0.;
    L(200,dd(x,p+d*x))
    C=-C+1.-exp(-x/3.);
    C.w=1.;
	glFragColor=C;
}
