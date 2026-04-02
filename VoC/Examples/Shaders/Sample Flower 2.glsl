#version 420

// original https://www.shadertoy.com/view/Md2yDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.2831853
#define INF 10.

const vec3 GREEN=vec3(0.098, 0.588, 0.011);
const vec3 PINK=vec3(1, 0.058, 0.247);

struct M{float d;vec3 c;};M m;
M mmin(M a, M b){if(a.d<b.d)return a;else return b;}
M mmax(M a, M b){if(a.d>b.d)return a;else return b;}

mat2 rz2(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}

float amod(float a,float m){return mod(a,m)-m*.5;}

float random(float x){return fract(sin(x*136.+4375.));}

// iq
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float leaf(vec3 p, float rmax){
    const float amax=1.;
    float a=atan(p.z,p.x);
    float r=cos(a/amax*TAU*.25)*rmax;
    float d=max((abs(a)-amax)*r, length(p.xz)-r);
    d=max(d,abs(p.y+pow(p.x,2.)*.2+exp(-abs(p.z)*5.*exp(-length(p.xz)*5.))*.2)-.01);
    return d;
}

void map(vec3 p){
    p.xz*=rz2(TAU*.25+sin(time*.2)*.5);
    p.xy*=rz2(.8);
    p.xz*=rz2(time*.5);
    float l=length(p.xz);
    float at=atan(p.z,p.x);

    float d=INF;
    
    for(int ri=0;ri<15;++ri){
        float RATIO=float(ri)/15.;
        float ANGLE=random(float(ri))*TAU;
        float SPANANGLE=2.0-RATIO*1.;
        float RADIUS=.1+.6*RATIO;
        float HEIGHT=mix(.8,1.,sqrt(RATIO));
        float OPENING=mix(-.1,.5,RATIO);
        
        float a=amod(at-ANGLE,TAU);
        float dr=min(d,(abs(a)-SPANANGLE)*l);
        float r=atan(p.y*5.)*4./TAU*RADIUS;
        r+=smoothstep(HEIGHT-.5,HEIGHT+.5,p.y)*OPENING*RADIUS;
        dr=max(dr,-length(p.xz)+r);
        dr=max(dr,length(p.xz)-r-.02);
        dr=max(dr,max(p.y-HEIGHT+pow(a,2.)*.2,0.));
        d=min(d,dr);
    }
    
    d=max(d,max(-p.y,0.));
    M mleaves=M(d,PINK);
    
    d=length(p.xz)-exp(-pow(p.y-0.3,2.)*10.)*.3;
    d=max(d,-p.y-.2);
    d=smin(d,length(p.xz-vec2(pow(p.y+.2,2.)*.2,0.))-.03,.02);
    d=max(d,p.y-.2);
    d=max(d,-p.y-2.);
    
    for(int li=0;li<5;++li){
        float RATIO=float(li)/5.;
        vec3 q=p;
        q.x-=pow(q.y+.2,2.)*.2;
        q.y+=.4+float(li)*.3+random(float(li))*.05;
        q.yz*=rz2(-(p.y+.2)*.2);
        q.xz*=rz2(fract(sin(float(li)*13.+45.))*TAU);
        d=smin(d,leaf(q,.5+RATIO*.3),.08);
    }
    
    M mbulb=M(d,GREEN);
    
    m=mmin(mleaves,mbulb);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 v=uv*(1.-uv);
    uv-=.5;
    uv.x*=resolution.x/resolution.y;
    vec3 ro=vec3(uv,-2),rd=vec3(uv,1),mp=ro;
    int i;
    for(i=0;i<50;++i){map(mp);if(m.d<.001)break;mp+=rd*.5*m.d;}
    float ma=1.-float(i)/50.;
    vec3 c=m.c;
    c*=ma;
    if(length(mp)>INF){
        c=vec3(0.058, 1, 0.631)*.2;
    }
    c=pow(c,vec3(1./2.2));
    c *= pow(v.x*v.y * 25.0, 0.25);
    glFragColor = vec4(c,1.);
}
