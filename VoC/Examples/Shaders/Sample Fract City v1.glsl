#version 420

// original https://www.shadertoy.com/view/7dGfDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
   
    Frac City
    08/02/22 | byt3_m3chanic

    An experiment while away with family. Trying to stay lean and simple,
    mostly doing some folding around a vector and making a simple box.
    Everything else based off a grid and each spaces hash value. 
    Using @Shane's multi-tap system to allow for the packed fractal forms. 
    --> https://www.shadertoy.com/view/WtffDS

    mouseable
*/

#define R resolution
#define M mouse*resolution.xy
#define T time

#define PI 3.141592653
#define PI2 6.28318530

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define H21(a) fract(sin(dot(a,vec2(21.23,41.32)))*43758.5453)
#define N(p,e) vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx))

float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }

float box( vec3 p, vec3 b ) {
    vec3 q = abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float box( vec2 p, vec2 b ) {
    vec2 d = abs(p)-b;
    return length(max(d,0.)) + min(max(d.x,d.y),0.);
}

float thrs=.15,xln,tm,tmod,ga1,ga2,ga3,ga4;
float mat,hash,smat,shash;
vec2 gid,sid;
vec3 hp,hitPoint;

const float scale = 2./.95;
const float scale_h = scale*.5;
const vec2 s = vec2(scale)*2.;
const vec2 pos = vec2(.5,-.5);
const vec2[4] ps4 = vec2[4](pos.yx,pos.xx,pos.xy,pos.yy);

float map(vec3 p3) {
    float r = 1e5;

    p3.x-= T*3.5;
    p3.y+= .6*sin(p3.x*.25+T*1.65);

    vec2 p,ip,id=vec2(0),ct=vec2(0);
  
    for(int i =0; i<4; i++){
        ct = ps4[i]/2. - ps4[0]/2.;
        p  = p3.xz - ct*s;
        ip = floor(p/s)+.5;
        p -= (ip)*s;
        vec2 idi = (ip+ct)*s;

        float hs = H21(idi),
             shs = hs;
        
        hs=floor(hs*9.)*.25;

        vec3 q = vec3(p.x,p3.y+2.-hs,p.y);

        if(shs>.75) q.x=-q.x;
        if(shs>.5) q.y=-q.y;
        
        if (q.x + q.y<0.) q.xy = -q.yx;
        if (q.x + q.z<0.) q.xz = -q.zx;
        if (q.y + q.z<0.) q.zy = -q.yz;
    
        q = abs(q);
        float k = (1.5 - .5)*2.;
        if (q.x < q.y) q.xy = q.yx; q.x = -q.x;
        if (q.x > q.y) q.xy = q.yx; q.x = -q.x;
        if (q.x < q.z) q.xz = q.zx; q.x = -q.x;
        if (q.x > q.z) q.xz = q.zx; q.x = -q.x;
        q.xyz = q.xyz*1.15 - k + 1.25;
        
        q.yz=abs(q.yz)-.95;
   
        vec2 bz = vec2(.52,.1+hs),
             bx = vec2(2.*bz.x+.01,.5+hs);
        
        float d = box(q,bz.xyx);
        if(d<r && fract(shs*33.72)>thrs) {
            r = d;
            sid=idi;
            shash=hs;
            hitPoint=q;
            smat = 2.;
        }

        
    }

    float f = p3.y+3.;
    if(f<r) {
        r = f;
        sid=vec2(15);
        shash=.0;
        hitPoint=p3;
        smat = 1.;
    }

    return r;
}

void main(void)
{
	vec2 F = gl_FragCoord.xy;
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
             
    vec3 C = vec3(0);
    vec3 p  = vec3(0),
         ro = vec3(0,0,7.25+3.25*sin(T*.09)),
         rd = normalize(vec3(uv,-1));

    float ttt = T*.5;
    
    tmod = mod(ttt, 10.);
    tm   = mod(ttt, 20.);
    
    float t1 = lsp(3.,  5., tmod);
    float t2 = lsp(8., 10., tmod);
    
    ga1 = ((t1-t2)*2.2)-1.1;

    float px = tm<10.? .78 : 1.57;
    float py = tm<10.? .78 : .0;

    vec3 c1 = tm<10.? vec3(.59,.92,.82) : vec3(.92,.78,.59);
    vec3 c2 = tm<10.? vec3(.23,.44,.38) : vec3(.52,.38,.17);
    
    xln = ga1-(.025*sin(uv.y*25.+T*5.));
    
    if(uv.x>xln) { 
    
        px = tm>5.&&tm<15.?.42:1.15;
        py = tm>5.&&tm<15.?-.68:2.45;
        
        c1 = tm>5.&&tm<15.? vec3(.58,.68,.92) : vec3(.88,.59,.87);
        c2 = tm>5.&&tm<15.? vec3(.33,.52,.97) : vec3(.44,.23,.40) ;
    }

    float x = px;
    float y = py;

    mat2 rx = rot(x), ry = rot(y);

    ro.yz*=rx; ro.xz*=ry; 
    rd.yz*=rx; rd.xz*=ry;

    float d=0.;
    for(int i=0;i<110;i++){
        p = ro+rd*d;
        float t = map(p);
        d += i<42?t*.25:t;
        if(d<t*1e-3||d>25.) break;
    }
    
    mat=smat;
    hash=shash;
    gid=sid;
    hp=hitPoint;
    
    if(d<25.){
        float t = map(p),
             sd = 1.,
              z = .01;

        vec2 e = vec2(d*1e-3,0);
        vec3 l = normalize(vec3(-5,9,-5)-p),
             n = t - N(p,e);
             n = normalize(n);

        for(float z=.01;z<18.;) {
            float h = map(p+l*z);
            if(h<1e-3) {sd=0.;break;}
            sd = min(sd, 18.*h/z);
            z+=h;
            if(sd<1e-3) break;
        }

        float diff = clamp(dot(n,l),.1,.8);
        diff=mix(diff,diff*sd,.75);

        vec3 h = vec3(.5);
        float px = 4./R.x;

        if(mat == 1.) {
            h = vec3(.1);

            vec2 uv = fract(hp.xz/scale);

            float d = min(
                length(abs(uv.x-.5))-.1,
                length(abs(uv.y-.5))-.1
                );

            float b=smoothstep(px,-px,abs(d)-.015);
            d=smoothstep(px,-px,d);

            h=mix(h,c2*.25,d);  
            h=mix(h,c1,b);  
        }

        if(mat == 2.) {
            float ss = floor(6./1.745);

            vec3 ff = floor(hp*ss)+gid.xyx,
                 vv = fract(hp*ss)-.5;

            float b = box(vv,vec3(.4))-.001;
            b=smoothstep(px,-px,b);

            h = vec3(.5);

            float hx = H21(ff.xy),
                  hy = H21(ff.yz),
                  hz = H21(ff.xz),
                  hs = (hx+hy+hz)/3.;
                  
            h = (hs>.8||hs<.2)? mix(h,c1,b):mix(h,vec3(hs),b);
            h = h*h*h;

        }

        C = h*diff;
    }
    
    float ux = (uv.y+.5)*.7;
    
    vec3 fog = mix(vec3(.01),c2,ux);
    C = mix(C,fog,1.-exp(-.0005*d*d*d));
    if(uv.x+.01>xln && uv.x-.01<xln)C=c1;
    C = pow(C,vec3(.4545));  
    glFragColor = vec4(C,1.);
}

