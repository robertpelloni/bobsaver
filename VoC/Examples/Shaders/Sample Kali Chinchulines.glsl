#version 420

// original https://www.shadertoy.com/view/WlBSWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float det=.002;
const float maxdist=15.;
float l=0.;
mat2 rotm;
vec3 basecol=vec3(.5,.5,1.);

mat3 lookat(vec3 dir, vec3 up){
    dir=normalize(dir);vec3 rt=normalize(cross(dir,normalize(up)));
    return mat3(rt,cross(rt,dir),dir);
}

mat2 rot2D(float a) {
    a=radians(a);
    float s=sin(a);
    float c=cos(a);
    return mat2(c,s,-s,c);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float kset(vec3 p) {
    for(int i=0; i<8; i++) {
        p=abs(p)/dot(p,p)-.8;
    }
    return length(p);
}

float de(vec3 p) {
    float x=p.x;
    p.y=abs(p.y+1.2)-1.2;
    float k=kset(abs(.5-fract(p)));
    float md=100.;
    float s=1.3;
    float sc=1.;
    vec3 pc;
    float esf=length(p+vec3(.0,1.,-1.))-.8+sin(time*7.)*.05;
    for (int i=0; i<9; i++) {
        p.x=abs(p.x); 
        p=p*s-vec3(1.,.5,2.);
        sc*=s;
        p.xz*=-rotm;
        p.xy*=rotm;
        vec3 ps=p+(cos(p.y)-sin(p.y))*.3;
        float d=length(ps.xz)-.15+sin(-time*8.+p.y*5.)*.05;
        if (d<md) {
            md=d;
            pc=ps;
        }
    }
    md=smin(md,esf,.7);
    pc*=esf*.5;
    l=max(0.,abs(.5-fract(pc.x))-k*.1)*.3;
    return md/sc*.9;
}

vec3 march(vec3 from, vec3 dir) {
    vec3 p, col=vec3(0.);
    float totdist=0., d,g=0.;
    for (int i=0; i<500; i++) {
        p=from+totdist*dir;
        d=de(p);
        totdist+=d;
        g+=(1.-length(p)*.25)*.8;
        if (totdist>maxdist||d<det) break;
    }
    col=vec3(3.,g*.3,g*.6)*l;
    col*=1.-totdist/maxdist;
    col+=vec3(0.,0.5,1.)*g*.01;
    return col;
}

void main(void)
{
    vec2 uv=gl_FragCoord.xy/resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    rotm=rot2D(35.-time);
    vec3 dir=normalize(vec3(uv,1.+cos(time*.2+20.)*.5));
    vec3 from=vec3(0.,0.,-5.);
    from.xz*=rot2D(time*10.);
    dir=lookat(-from,vec3(1.,1.,0.))*dir;
    vec3 col=march(from, dir);   
    col=mix(vec3(0.),col,min(1.,time*.2));
    col*=mod(gl_FragCoord.y,3.)*.7;
    glFragColor = vec4(col,1.0);
}
