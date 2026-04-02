#version 420

// original https://www.shadertoy.com/view/cdfyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #041
    06/21/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R            resolution
#define T             time
#define M             mouse*resolution.xy

#define PI          3.141592653
#define PI2         6.283185307

#define MIN_DIST    1e-3
#define MAX_DIST    55.

// constants
const float size = 1.35;
const float hlf = size*.5;
const float xlf = hlf*.5;

vec3 hit,hitPoint;
vec2 gid,sid;
mat2 r90,r45;
float speed,glowa,glowb;

mat2 rot(float a){return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }

//@iq sdfs & extrude
float box( vec3 p, vec3 b ){
    vec3 q = abs(p) - b;return length(max(q,0.)) + min(max(q.x,max(q.y,q.z)),0.);
}
float box(vec2 p, vec2 a) {
    vec2 q=abs(p)-a;return length(max(q,0.))+min(max(q.x,q.y),0.);
}
float cap( vec3 p, float h, float r ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);return min(max(d.x,d.y),0.) + length(max(d,0.));
}
float opx(in float sdf, in float pz, in float h) {
    vec2 w = vec2( sdf, abs(pz) - h );return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

vec2 map(vec3 pos, float sg){
    vec2 res = vec2(1e5,0);

    pos-=vec3(0,0,speed);

    float sw = .2+.2*sin(pos.z*.63);
    sw -= .3+.2*cos(pos.x*.73);
    pos.y-=sw;
    
    vec2 uv = pos.xz;
    vec2 id = floor((uv+hlf)/size);
    vec2 q = mod(uv+hlf,size)-hlf;
    
    vec3 pp = vec3(q.x,pos.y,q.y);

    float rnd = hash21(id);
    float rdm = fract(rnd*42.79);
    
    if (rnd>.5) {q.x = -q.x; pp.xz*=r90;}
    rnd = fract(rnd*32.781);
    
    float mv = .02, mx = mv*3.5;
    const vec3 b2 = vec3(1.,.15,hlf);

    vec2 spc = vec2(-hlf,.0);
    vec2 p2 = vec2(length(q+spc),length(q-spc));
    vec2 pq = p2.x<p2.y? q+spc : q-spc;

    pq *= r45;

    float d = length(pq.x);
    if(rnd>.85) d = min(length(q.x),length(q.y));

    d = abs(d)-mv;

    float pl = length(vec2(abs(q.x)-hlf,q.y))-(mx);
          pl = min(length(vec2(q.x,abs(q.y)-hlf))-(mx),pl);

    float d3 = opx(d,pos.y,.05);
    float ct = box(pp,vec3(hlf,5,hlf));
    d3=max(max(d3,ct),-(pl));
    if(d3<res.x) {
        res = vec2(d3,2.);
        hit = pos-vec3(0,sw,0);
    }

    float pole = opx(abs(pl)-.01,pos.y, .055);
    if(pole<res.x) {
        res = vec2(pole,3.);
        hit = pos;
    }
    
    float bx=1e5,rx=1e5,cx=1e5,lx=1e5;
    if(rnd<.675 && rdm>.75){
        pp.xz*=r45;
        bx = box(pp,vec3(xlf,.05,xlf*.5))-.01;
    }else if(rnd<.675 && rdm>.5){
        pp.xz*=r45;
        pp = vec3(abs(abs(pp.x)-(.125*size))-(.0625*size),pp.yz);
        rx = cap(pp.yzx,.74*xlf,.01*size)-.03;
    }else if(rnd<.675 && rdm<.2){
        pp.y-=.2;
        cx = cap(pp,.2,.15)-.01;
    }else if(rnd<.675) {
        lx = cap(pp,.1,.001)-.05;
        bx=min(bx,cap(pp+vec3(0,.05,0),.03,.075));
    }
    rdm = fract(rnd*42.79);
    if(bx<res.x) {
        res = vec2(bx,4.);
        hit = pp;
    }
    if(rx<res.x) {
        res = vec2(rx,7.);
        hit = pp;
    }
    if(cx<res.x) {
        res = vec2(cx,8.);
        hit = pp;
    }  
    if(lx<res.x) {
        res = vec2(lx,9.);
        hit = pp;
    } 
    float flr =pos.y+.05;
    if(flr<res.x) {
        res = vec2(flr,1.);
        hit = pos;
    }
           
    if(sg==1.&&lx<bx) { 
        if(rdm>.5) {glowa += .0005/(.0001+lx*lx);}else{glowb += .0005/(.0001+lx*lx);}
    }
    return res;
}

//Tetrahedron technique
//https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e,0. ).x + 
                      h.yyx*map( p + h.yyx*e,0. ).x + 
                      h.yxy*map( p + h.yxy*e,0. ).x + 
                      h.xxx*map( p + h.xxx*e,0. ).x );
}

vec2 marcher(vec3 ro, vec3 rd,float cnt) {
    float d = 0., m = 0.;
    for(int i=0;i<128;i++){
        vec2 ray = map(ro + rd * d,cnt>0.?0.:1.);
        if(ray.x<MIN_DIST*d||d>MAX_DIST) break;
        d += i<64?ray.x*.4:ray.x*.8;
        m  = ray.y;
    }
    return vec2(d,m);
}

//@iq hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1., 0., 1. );
    return c.z * mix( vec3(1), rgb, c.y);
}

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, inout float d, vec2 uv, float cnt) {

    vec3 C = vec3(0);
    float m = 0.;
    vec2 ray = marcher(ro,rd,cnt);
    d=ray.x;m=ray.y;
    
    // save globals post march
    hitPoint = hit;  
    sid = gid;
    vec3 p = ro + rd * d;
    if(d<MAX_DIST)
    {
             p = ro + rd * d;
        vec3 n = normal(p,d);
        vec3 lpos =vec3(-6.,12.,12.);
        vec3 l = normalize(lpos-p);
        
        float diff = clamp(dot(n,l),.09,.99);
        
        float shdw = 1.;
        for( float t=.01; t < 16.; ) {
            float h = map(p + l*t,0.).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 14.*h/t);
            t += h;
            if( shdw<MIN_DIST ) break;
        }
        diff = mix(diff,diff*shdw,.65);
        
        vec3 h = vec3(.5);

        if(m==1.) {
            float px = 2./R.x; 
            vec2 dp = p.xz;
            dp.y-=speed;
            vec3 k = vec3(0.012,0.149,0.047);
            vec2 id = floor(dp.xy*6.), q = fract(dp.xy*6.)-.5;
            float hs = hash21(id.xy);

            if(hs>.5)  q.xy *= rot(1.5707);
            hs = fract(hs*575.913);

            float mv = .1;

            vec2 spc = vec2(-.5,.0);
            vec2 p2 = vec2(length(q+spc),length(q-spc));
            vec2 pq = p2.x<p2.y? q+spc : q-spc;

            pq *= r45;

            float td = length(pq.x);
            td=abs(td)-mv;

            if(hs>.85) td = min(length(q.x)-mv,length(q.y)-mv);
            float b = length(vec2(abs(q.x)-.5,q.y))-(mv*1.75);
            b = min(length(vec2(q.x,abs(q.y)-.5))-(mv*1.75),b);
            td = min(b,td);
            h = mix(k,k*.75,smoothstep(px,-px,td));
            ref = vec3(td);
        }
        if(m==2.) { 
            h = hsv2rgb(vec3(hitPoint.z*.02,1.,.3)); 
            ref = h; 
        }
        if(m==3.) { h = vec3(.1); ref = h; }
        if(m==4.) { h = vec3(.05); ref = vec3(.35); }
        if(m==5.) { 
            h = hsv2rgb(vec3(-hitPoint.z*.02,.75,.3)); 
            ref = h; 
        }
        if(m==6.) { 
            vec2 f = fract(hitPoint.xz*.5)-.5;
            h = vec3(.01);
            if(f.x*f.y>.0)h=vec3(.1);
            ref = h; 
        }
        if(m==7.) { 
            h = vec3(0.255,0.161,0.086); 
            float ft = fract((hitPoint.z+.4)*8.)-.5;
            float fmod = mod(floor(ft),3.);
            if(hitPoint.z>-.15) h = mix(h,hsv2rgb(vec3((p.z-speed)*.5,.8,.1)),fmod==0.?1.:0.);
            
            ref = h*.5; 
        }
        if(m==8.) { 
            vec2 hp = hitPoint.xz;
            float d = length(hp)-.1;
            float b = box(hp-vec2(.5,0),vec2(.5,.05));
            float px = 4./R.x;
            h = vec3(.012,.227,.427); 
            h = mix(h,vec3(0.349,0.506,0.651),smoothstep(px,-px,b));
            h = mix(h,vec3(.1),smoothstep(px,-px,d));
            ref = h*.5; 
        }
        
        C = (diff*h);

        ro = p+n*.001;
        rd = reflect(rd,n);
    } 

    return vec4(C,d);
}

mat2 rx,ry;
vec3 FC = vec3(0.114,0.227,0.137);

void main(void)
{
    r45 = rot(.7853981634);
    r90 = rot(1.5707);
    speed = T*2.05;
    
    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,0,5.);
    vec3 rd = normalize(vec3(uv,-1));

    float x = 0.; //M.xy==vec2(0) || M.z <0. ? .0 : (M.y/R.y * .24-.12)*PI;
    float y = 0.; //M.xy==vec2(0) || M.z <0. ? .0 : (M.x/R.x * 1.0-.50)*PI;

    float ff = .45+.25*cos(T*.065), fx = .55*sin(T*.113);

    rx = rot(-(.28+ff)-x), ry = rot(-fx-y);
    
    ro.zy *= rx; ro.xz *= ry; 
    rd.zy *= rx; rd.xz *= ry;
    
    // reflection loop (@BigWings)
    vec3 C = vec3(0);
    vec3 ref=vec3(0), fil=vec3(.95);
    float d =0.,a=0.;
    
    // up to 4 is good - 2 average bounce
    for(float i=0.; i<2.; i++) {   
        //glowa=0.;glowb=0.;
        vec4 pass = render(ro, rd, ref, d, uv, i);
        C += pass.rgb*fil;
        fil*=ref;
        if(i==0.)a=pass.w;
     
    }
      
    C = mix(C,vec3(0.941,0.459,0.459),clamp(glowa*.5,0.,1.));
    C = mix(C,vec3(0.420,0.749,0.353),clamp(glowb*.5,0.,1.));
    
    C = mix(FC,C,exp(-.00025*a*a*a));
  
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1);
}
