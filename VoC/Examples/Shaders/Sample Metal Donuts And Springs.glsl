#version 420

// original https://www.shadertoy.com/view/stjSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Metal Art Donuts &Springs
    @byt3_m3chanic | 08/17/21

    you dont learn till you do it over and over and over...
    Just trying to isolate the UV mapping things
    playing around with animation and movement.
    
    truchet tiles are so hot right now!

*/

#define R resolution
#define M mouse*resolution.xy
#define T time

#define PI  3.14159265359
#define PI2 6.28318530718

#define MIN_DIST .001
#define MAX_DIST 90.

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }

//@iq torus
float torus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec3 hit,hitPoint,sto,gto;
vec2 gid,sid;

const vec2 sc = vec2(.125), hsc = .5/sc; 

vec2 map(vec3 p) {
    p.y+=2.;
    p.x+=time;
    vec2 res = vec2(1e5,0);
    
    vec2 id = floor(p.xz*sc) + .5;    
    vec2 r = p.xz - id/sc;
    vec3 q = vec3(r.x,p.y,r.y);

    float dir = mod(id.x+id.y,2.)<.5? -1. : 1.;
    float rnd = hash21(id);

    float mx = .7+.3*sin(id.x*1.25);
    float my = .7+.3*sin(id.y*2.);
    float fid = (mx*my);
    float wv = 1.65*sin(fid*T*4.5);
 
    // spheres
    float b1 = rnd >.2 ? length(q-vec3(0,1.8-wv,0))-(fid) : 1e5;
    float w1=wv*.3;
    float w2=wv*.15;
    vec3 vq = vec3(q.x,abs(abs(q.y-.75-w2)-.5)-.25,q.z);
    b1 = min(torus(vq,vec2(1.25-w1,.075)),b1);
    if(b1<res.x) {
        res = vec2(b1,2.);
        hit=p;
        gid=id;
        gto=vec3(fid,dir,rnd);
    }

    float b2 = torus(q-vec3(0, 1.05,0),vec2(2.75 ,1.00 ));
    if(b2<res.x) {
        res = vec2(b2,3.);
        hit=q;
        gid=id;
        gto=vec3(fid,dir,rnd);
    }
    
    // floor
    float d9 = p.y;
    d9 = max(d9,-(length(q)-1.25));
    if(d9<res.x) {
        res = vec2(d9,1.);
        hit=p;
        gid=id;
        gto=vec3(fid,dir,rnd);
    }

    return res;
}

vec3 normal(vec3 p, float t)
{
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

vec3 hue(float t)
{ 
    vec3 d = vec3(0.961,0.541,0.220);
    return .375 + .375*cos(PI2*t*(vec3(.985,.98,.95)+d)); 
}

vec4 FC = vec4(0.306,0.337,0.353,0.);

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last, inout float d) {

    vec3 C = vec3(0);
    float m = 0.;
    vec3 p = ro;
    
    for(int i=0;i<150;i++)
    {
        p = ro + rd * d;
        vec2 ray = map(p);
        if(abs(ray.x)<MIN_DIST*d||d>MAX_DIST)break;
        d += i<32? ray.x*.5: ray.x*.85;
        m  = ray.y;
    } 

    hitPoint = hit;
    sid = gid;
    sto = gto;
    
    float alpha = 0.;
    if(d<MAX_DIST)
    {
        vec3 n = normal(p,d);
        vec3 lpos =  vec3(1,8,0);
        vec3 l = normalize(lpos-p);

        float diff = clamp(dot(n,l),0.,1.);
        float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.);
        fresnel = mix(.01, .7, fresnel);

        float shdw = 1.0;
        for( float t=.05; t < 18.; ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 18.*h/t);
            t += h;
            if( shdw<MIN_DIST || t>32. ) break;
        }
        diff = mix(diff,diff*shdw,.75);

        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec =  0.5 * pow(max(dot(view, ret), 0.), 14.);

        vec3 h = vec3(.5);
        
        if(m==1.) {
            vec3 hp = hitPoint*sc.xxx;
            h = vec3(.7);
            vec2 f = fract(hp.xz*2.)-.5;
            if(f.x*f.y>0.) h=clamp( hue( fresnel-length(hp.xz*.15) )+.2,vec3(0),vec3(1) );
            ref = vec3(h*.5)-fresnel;
        }
        
        if(m==2.) {
            h=vec3(.5);
            ref = h-fresnel;
        }

        if(m==3.) {
            vec3 hp = hitPoint;
            float fhs = hash21(sid.xy+50.);
            float angle = atan(hp.z,hp.x)/PI2;
            float gz =  atan( hp.y,  length(hp.zx)-2.75 ) / PI2;

            vec2 uv = vec2(angle,gz+(T*.1*fhs));
        
            float px  = .005*d;
            vec2 scaler = vec2(48.,32.);
            vec2 grid = fract(uv.xy*scaler)-.5;
            vec2 id   = floor(uv.xy*scaler);
            float hs = hash21(id);
            if(hs>.5) grid.x*=-1.;

            float chk = mod(id.y + id.x,2.) * 2. - 1.;

            vec2 d2 = vec2(length(grid-.5), length(grid+.5));
            vec2 gx = d2.x<d2.y? vec2(grid-.5) : vec2(grid+.5);

            float circle = length(gx)-.5;
            
            if(fhs>.4){
                float circle2 = fhs>.85 ? abs(abs(circle)-.25)-.2 : abs(abs(circle)-.15)-.05 ;
                circle2=smoothstep(-px,.001+px,circle2);
                circle=(chk>0.^^ hs>.5) ? smoothstep(-px,.001+px,circle) : smoothstep(.001+px,-px,circle);
                
                if(fhs>.75) circle= min(circle2,circle);
                     
            }else{
            
                circle=smoothstep(-px,.001+px,abs(circle)-.15);
            }
           
        
            h = mix(h, hue(fresnel-(sto.z*3.35)),circle);
            ref = vec3(.4-circle)-fresnel;
        }
        
        C = h*diff+spec;
        C = mix(FC.rgb,C,  exp(-.00005*d*d*d));
    
        ro = p+n*.01;
        rd = reflect(rd,n);
    
    }else{
        C = FC.rgb;
    } 
    return vec4(clamp(C,vec3(.03),vec3(1.)),alpha);
}

float zoom = 14.;
void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;

    //time = T*.75;
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    
    float x = -1.;
    
    //if(M.z>0.) x = .5-(M.x-F.x);
     
    //if(uv.x>x && M.z>0.) zoom *= .5;
    vec3 ro = vec3(uv*zoom,-zoom);
    vec3 rd = vec3(0,0,1.);

    mat2 rx = rot(-45.*PI/180.);
    mat2 ry = rx;
    ro.yz *= rx;
    rd.yz *= rx;
    ro.xz *= ry;
    rd.xz *= ry;

    vec3 C = vec3(0);
    vec3 ref=vec3(0); 
    vec3 fil=vec3(1);
    
    float d =0.;
    float numBounces = 2.;
    
    for(float i=0.; i<numBounces; i++) {
        d =0.;
        vec4 pass = render(ro, rd, ref, i==numBounces-1., d);
        C += pass.rgb*fil;
        fil*=ref;
    }

    //C = mix(C,C+.07,hash21(uv));
    C=clamp(C,vec3(.03),vec3(.9));
    // gamma correction
    C = pow(C, vec3(.4545));
    O = vec4(C,1.0);

    glFragColor = O;
}
