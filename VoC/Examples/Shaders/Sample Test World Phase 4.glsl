#version 420

// original https://www.shadertoy.com/view/fdtyDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
        
    Test World Phase 4    
    8/16/22 | byt3 m3chanic
    
    Same ole trick, trying refraction and fumbling with a single pass multi
    bounce marcher - thanks @blackle / @tdhooper / and sdf's @iq
*/

#define R         resolution
#define T         time
#define M         mouse*resolution.xy

#define PI              3.14159265358
#define PI2             6.28318530718

#define MAX_DIST    40.

// AA Setting - comment/uncomment to disable/endable AA from render
#define AA 2

float mtime=0.;
float hash21(vec2 a) { return fract(sin(dot(a,vec2(21.23,41.232)))*41458.5453); }
mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a));}

//@iq SDF functions
float box( vec3 p, vec3 b ){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float cap( vec3 p, float h, float r ){
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//global vars
vec3 hit=vec3(0), hitPoint=vec3(0);
float travelSpeed,modTime,fractTime;

const float size = 20.;
const float rep_half = size/2.;
const float rr = rep_half/2.;

vec2 map(vec3 pos) {
    vec2 res = vec2(1e5,-1.);
    vec3 center = vec3(0,-2, -rr);

    vec3 pp = pos-center;
    vec3 tt = pp;
    vec3 sp = pp;

    vec3 pi = vec3(
        floor((pp + rep_half)/size)
    );
    vec3 ti = pi;

    float bfs,fhs,dhs;
    if(modTime<2.){
        fhs = hash21(pi.xz);
        if(fhs>.57){
            tt.y += fractTime;
        } else {
            tt.y -= fractTime;
        } 
    } else if (modTime<4.){
          dhs = hash21(pi.zy+vec2(4,.4));
        if(dhs>.67){
            tt.x += fractTime;
        } else {
            tt.x -= fractTime;
        }
    } else {
          bfs = hash21(pi.xy+vec2(21,.4));
        if(bfs>.27){
            tt.z -= fractTime;
        } else {
            tt.z += fractTime;
        }   
    }

    pp =  mod(pp+rep_half,size) - rep_half;
    tt =  mod(tt+rep_half,size) - rep_half;

    float thk = 1.;
    float d1 = length(abs(pp.xy)-vec2(10))-thk;
    d1 = min(length(abs(pp.xz)-vec2(10))-thk,d1);
    d1 = min(length(abs(pp.yz)-vec2(10))-thk,d1);
    if(d1<res.x) {
        res = vec2(d1,3);
        hit = abs(pp)-vec3(10);
    }

    d1 = min(cap(abs(pp)-vec3(10,0,10),1.5,1.5),d1);
    d1 = min(cap(abs(pp.yzx)-vec3(10,0,10),1.5,1.5),d1);
    d1 = min(cap(abs(pp.zxy)-vec3(10,0,10),1.5,1.5),d1);
    if(d1<res.x) {
        res = vec2(d1,6);
        hit = abs(pp)-vec3(10);
    }

    float d2 = box(abs(pp)-vec3(10), vec3(3.5))-.05;
    d2=max(d2,-(abs(d1)-.5));
    if(d2<res.x) {
        res = vec2(d2,2);
        hit = abs(pp)-vec3(10);
    }

    float d5 = length(tt)-2.35;
    if(d5<res.x) {
        res = vec2(d5,4);
        hit = tt;
    }

    return res;
}

vec3 normal(vec3 p, float t, float mindist){
    t*=mindist;
    float d = map(p).x;
    vec2 e = vec2(t,0);
    vec3 n = d-vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
    );
    return normalize(n);
}

vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n){
    n = normal(p,d,1.);
  
    vec3 lpos = vec3(5,9,-7);
    vec3 l = normalize(lpos-p);
    float diff = clamp(dot(n,l),0.,1.);
    vec3 h=vec3(.05);

    if(m==2.) {
        vec3 dv = p-vec3(0,0, -rr/2.);
        vec3 f=fract(dv)-.5;
        if(f.x*f.y*f.z>.0) h = vec3(1);
        
        float px = 4./R.x;
        float d1 = length(hitPoint)-4.5;
        float d2 = smoothstep(px,-px,abs(d1)-.05);
        d1=smoothstep(px,-px,d1);
        float cut = clamp((p.y*.03)+.2,0.,1.);
        h=mix(h,vec3(.8,.47,0.),d1);
        h=mix(h,vec3(.05),d2);
    }

    if(m==3.) {
        float bg = clamp(sin(length(hitPoint)*22.)*1.5-.5,.01,.99);
        h=mix(vec3(.37,.55,.57),vec3(.063,.11,.12),bg);
    }
    if(m==4.) h=vec3(.05);
    if(m==6.) h=vec3(.3);
    return diff*h;
}

vec3 renderFull(vec2 uv)
{

    vec3 C=vec3(.0);
    float fA = 0.;
    vec3 ro = vec3(0,-1,10.15),
         rd = normalize(vec3(uv,-1));

    mat2 mx =rot(-(.65*sin(T*.08))); mat2 my =rot(-.55+(.2*cos(T*.1)));
    
    ro.zy*=mx;rd.zy*=mx;
    ro.xz*=my;rd.xz*=my;
    
    vec3  p = ro + rd * .0001;
    float atten = 1.;
    float k = 1.;
    float bounce = 4.;

    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    // a lot of these settings are tweaked for this scene 
    for(int i=0;i<128;i++)
    {
        vec2 ray = map(p);
        vec3 n = vec3(0);
        float d = i<32? ray.x*.5:ray.x*.9;
        float m = ray.y;
        p += rd*d*k;

        hitPoint=hit;
        if(bounce>2.)fA+=d;

        if (d*d < 1e-5) {
            bounce--;
            C+=shade(p,rd,d,ray.y,n)*atten;
            if(m!=4.&&m!=6.) break;
            
            atten *= .45;
            p += rd*.1;
            k = sign(map(p).x);
            vec3 rf=refract(rd,n,.65);
            
            if(m==6.){
                rf=reflect(-rd,n);  
            }
            
            p+=n*.5;
            rd=rf;

        }

        if(bounce<1.||distance(p,rd)>75.) break;
    }

    if(fA>0.) C=mix(C,vec3(.03), 1.-exp(-.00001*fA*fA*fA));
    return clamp(C,vec3(0),vec3(1)); 
}

void main(void) {

    vec3 col = vec3(.00); 
 
    mat2 r15 = rot(-25.*PI/180.);
    fractTime = fract(time*.3)* (size);
    modTime = mod(time*.6,6.);
    
    vec2 o = vec2(0);
    vec2 xv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    
    vec2 ff = fract(xv*5.+T*.5)-.5;
    float wv = .2 * sin(xv.x*.75+T*1.5);
    xv.y+=wv;

    if(ff.x*ff.y>0.&&(xv.y>.35||xv.y<-.35)) col=vec3(.9);

    if(xv.y<.35&&xv.y>-.35){
    // @tdhooper 
    // @iq https://www.shadertoy.com/view/3lsSzf
    #ifdef AA
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        o = vec2(float(m),float(n)) / float(AA) - .5;
    #endif
        
        //time = mod(time, 1.);
        vec2 p = (-resolution.xy + 2. * (gl_FragCoord.xy + o)) / resolution.x;
        col += renderFull(p);
        
    #ifdef AA
    }
    col /= float(AA*AA);
    #endif
    }
    
    float px = 2./R.x;
    float f1 = length(abs(xv.y)-.35)-.005;
    float f2 = smoothstep(.02+px,-px,f1);
    f1 = smoothstep(px,-px,f1);
    if(xv.y>.35||xv.y<-.35)col = mix(col,col*.4,f2);
    col = mix(col,vec3(.8,.47,0.),f1);
    col = pow( col, vec3(.4545) );
    glFragColor = vec4(col, 0);
}
