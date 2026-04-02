#version 420

// original https://www.shadertoy.com/view/ml3SRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #029
    06/01/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 

*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define P9          1.57078
#define PI          3.14159265359
#define PI2         6.28318530718

#define MIN_DIST    .0001
#define MAX_DIST    50.

// globals
float hspeed=0.,tspeed=0.,fspeed=0.,tmod=0.,ga1=0.,ga2=0.,ga3=0.,ga4=0.;
vec3 hp=vec3(0),hitpoint=vec3(0);
vec4 FC=vec4(.19,.22,.23,0);
mat2 ra1,ra2,ra3,ra4;

// consts for sizing (1-5 - more than that you'll need to move the camera back)
const float csize = 4.;
const float dsize = csize*4.;
const float xsize = dsize*2.;
const float psize = csize/2.;
const vec2[4] ps4 = vec2[4](vec2(-csize,-csize),vec2(-csize,csize),vec2(csize,csize),vec2(csize,-csize));

// standard bag of tricks
mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){return fract(sin(dot(p,vec2(23.43,84.21)))*4832.3234);}
float lsp(float b, float e, float t){return clamp((t-b)/(e-b),0.,1.); }
float ezin(float n) {n = n*n*n; return n;}
float box(vec3 p, vec3 b) { vec3 q = abs(p) - b; return length(max(q,0.)) + min(max(q.x,max(q.y,q.z)),0.);}

//@iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.+vec3(0,4,2),6.)-3.)-1., 0., 1.0 );
    return c.z * mix( vec3(1), rgb, c.y);
}

// rotate from corner based on id
void rov(inout vec2 q, int ct, mat2 ga){
    q-=ps4[ct];
    q*=ga;
    q+=ps4[ct];
}

// truchet pattern
vec3 getFace(vec2 uv) {
    vec2 id = floor(uv);
    vec2 gv = fract(uv)-.5;
    float px = 12./R.x;
    float rnd = hash21(id);
    
    if(rnd<.34) gv.x = -gv.x;
    
    vec2 d2 = vec2(length(gv-.5), length(gv+.5));
    vec2 gx = d2.x<d2.y? vec2(gv-.5) : vec2(gv+.5);
    float cx = length(gx)-.5;
    float d5 = abs(max(abs(gv.x),abs(gv.y))-.5)-.005;
    
    if(rnd>.65) cx = min(length(gv.x)-.005,length(gv.y)-.005);

    vec3 h = vec3(.0);
    vec3 clr = hsv2rgb(vec3((uv.x+uv.y)*.15,1.,.5));
    h = mix(h, clr,smoothstep(-px,px,abs(abs(cx)-.125)-.05));
    h = mix(h, vec3(.5),smoothstep(-px,px,abs(cx)-.125));
    h = mix(h, vec3(.1),smoothstep(px,-px,d5));
    return h;
}

vec2 map(vec3 p) {
    vec2 res = vec2(1e5,0.);
    p.x-=fspeed;
    vec3 q = p-vec3(csize-1.);
    
    if(ga1>0.) rov(q.xy,0,ra1);
    if(ga2>0.) rov(q.xy,1,ra2);
    if(ga3>0.) rov(q.xy,2,ra3);
    if(ga4>0.) rov(q.xy,3,ra4);

    float d1 = box(q,vec3(csize)-.025)-.025;
    if(d1<res.x) {
        res=vec2(d1,1.);
        hp=q;
    }
    
    float d2 = p.y+1.;
    if(d2<res.x) {
        res=vec2(d2,2.);
        hp=p;
    }

    return res;
}

vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

// low steps - its just a cube and a floor
vec2 marcher(vec3 ro, vec3 rd) {
    float d = 0., m = 0.;
    for(int i=0;i<100;i++){
        vec2 ray = map(ro + rd * d);
        if(ray.x<MIN_DIST*d||d>MAX_DIST) break;
        d += i<32?ray.x*.35:ray.x*.85;
        m  = ray.y;
    }
    return vec2(d,m);
}

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, float last, inout float d, vec2 uv) {

    vec3 C = vec3(0);
    vec2 ray = marcher(ro,rd);
    float m =ray.y; d=ray.x;
    
    hitpoint=hp;

    if(d<MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        // light
        vec3 lpos =vec3(-25.,15.,10.);
        vec3 l = normalize(lpos-p);
        // difused
        float diff = clamp(dot(n,l),.09,.99);
        // shadow
        float shdw = 1.;
        for( float t=.01; t < 12.; ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 12.*h/t);
            t += h;
            if( shdw<MIN_DIST ) break;
        }
        diff = mix(diff,diff*shdw,.65);
        // color
        vec3 h = vec3(1.);
        // texture - cube - floor
        vec2 cuv; vec3 tn = n; int face = 0;
        if(m==1.) {
            // match rotation
            if(ga1>0.) tn.xy*=ra1;
            if(ga2>0.) tn.xy*=ra2;
            if(ga3>0.) tn.xy*=ra3;
            if(ga4>0.) tn.xy*=ra4;
            
            //@Shane https://www.shadertoy.com/view/3sVBDd
            //finding the face of a cube using the normal
            vec3 aN = abs(tn);
            ivec3 idF = ivec3(tn.x<-.25? 0 : 5, tn.y<-.25? 1 : 4, tn.z<-.25? 2 : 3);
            face = aN.x>.5? idF.x : aN.y>.5? idF.y : idF.z;
            // assign vec2 from hitpoint
            if(face==0) cuv = hitpoint.zy+12.;
            if(face==1) cuv = hitpoint.zx-8.;
            if(face==2) cuv = hitpoint.xy;
            if(face==3) cuv = hitpoint.yx-4.;
            if(face==4) cuv = hitpoint.zx+24.;
            if(face==5) cuv = hitpoint.zy+8.;

            cuv*=.5;
            cuv-=psize;
            h = getFace(cuv);
            ref = h*.4;
        };
        if(m==2.) {
            cuv = p.xz-vec2(hspeed,0.)-1.;
            h = getFace(cuv*.5);
            ref = h*.8;
        };
        
        C = (diff*h);
        ro = p+n*.005;
        rd = reflect(rd,n);
    } 
    if(last>0.) C = mix(FC.rgb,C,exp(-.00008*d*d*d));
    return vec4(C,d);
}

void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{   
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    // precal 
    tspeed = T;
    tmod = mod(tspeed,10.);
    if(tmod==10.) { 
        // every loop move cube back
        fspeed +=dsize;hspeed +=dsize;
    } 
    // cube floor speed
    fspeed = fract(T*.1)*xsize;
    // texture speed
    hspeed = (T*.1)*xsize;
    
    // timing
    ga1 = ezin(lsp(0.,1.5,tmod));
    ga2 = ezin(lsp(1.5,3.,tmod));
    ga3 = ezin(lsp(3.,4.5,tmod));
    ga4 = ezin(lsp(4.5,6.,tmod));

    // rotation precal
    if(ga1>0.) ra1 = rot(ga1*P9);
    if(ga2>0.) ra2 = rot(ga2*P9);
    if(ga3>0.) ra3 = rot(ga3*P9);
    if(ga4>0.) ra4 = rot(ga4*P9);
    
    // standard setup uv/ro/rd
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(csize,-1.5,18.5);
    vec3 rd = normalize(vec3(uv,-1));

    // mouse
    float x = 0.;
    float y = 0.;

    float ff = 1.5707+(.33*sin(T*.2));
    mat2 rx = rot(-.52-x), ry = rot(-ff-y);
    ro.zy *= rx; ro.xz *= ry; 
    rd.zy *= rx; rd.xz *= ry;
    
    // reflection loop (@BigWings)
    vec3 C = vec3(0);
    vec3 ref=vec3(0), fil=vec3(.95);
    float d =0.,a=0.;

    for(float i=0.; i<2.; i++) {
        vec4 pass = render(ro, rd, ref, i, d, uv);
        C += pass.rgb*fil;
        fil*=ref;
        if(i==0.)a=pass.w;
    }
           
    C = mix(FC.rgb,C,exp(-.00008*a*a*a));
    C=pow(C, vec3(.4545));
    O = vec4(C,1);
    
    glFragColor=O;
}