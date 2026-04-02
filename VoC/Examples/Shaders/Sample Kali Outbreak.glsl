#version 420

// original https://www.shadertoy.com/view/3dBczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float det=.001,maxdist=12.,t, vcol;
vec3 ldir=vec3(-2.,1.,.5);

mat2 rot(float a) {
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float de(vec3 pos) {
    pos.xz*=rot(.3);
    float sc=1.2, d=1000., der=1.;
    vec3 p=pos, mp=vec3(0.);
    for (int i=0; i<13; i++) {
        p.xz*=rot(1.);
        p.yz*=rot(t);
        p.x=abs(p.x);
        p=p*sc-vec3(2.5,0.,0.);
        der*=sc;
        float z=length((fract(p*5.)-.5)*2.);
        float c=length(p)-.4-pow(4.*z*(1.-z),2.)*.008;
        if (c<d) {
            d=c;
            mp=p;
        };
    }
    vcol=length(mp);
    return d/der*.8;
}

vec3 normal(vec3 p) {
    vec3 e=vec3(0.,det,0.);
    return normalize(vec3(de(p+e.yxx),de(p+e.xyx),de(p+e.xxy))-de(p));
}

vec3 shade(vec3 p, vec3 dir) {
    vec3 n=normal(p);
    ldir=normalize(ldir);
    float amb=.1;
    float dif=max(0.,dot(ldir,-n));
    vec3 ref=reflect(ldir,dir);
    float spe=pow(max(0.,dot(ref,n)),8.)*.8;
    vec3 col=mix(vec3(1.),vec3(1.,.0,0.),pow(vcol*4.2-1.,10.));
    return col*(amb+dif*.5)+spe*.8;
}

vec3 march(vec3 from, vec3 dir) {
    vec3 p, col=vec3(0.);
    float totdist=0.,d;
    for(int i=0; i<200; i++) {
        p=from+totdist*dir;
        d=de(p);
        if (d<det || totdist>maxdist) break;
        totdist+=d;
    }
    if (d<det) {
        p-=dir*det*2.;
        col=shade(p,dir);
    } else totdist=maxdist;
    float f=1.-totdist/maxdist;
    return col*f*1.5;
}

void main(void)
{
    t=time*.15+22.*.15;
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    vec3 from = vec3(0,0,-7.);
    vec3 dir = normalize(vec3(uv,1.5));
    vec3 col = march(from, dir);
    glFragColor = vec4(col,1.0)*smoothstep(0.1,1.,abs(sin(t)));
}
