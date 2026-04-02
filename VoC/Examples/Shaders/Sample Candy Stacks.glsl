#version 420

// original https://www.shadertoy.com/view/fdV3Rm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    
    Candy Stacks 
    @byt3_m3chanic | 09/10/21

    work on some timing/motion stuff.
    built mechanics first
    
*/

#define R   resolution
#define M   mouse*resolution.xy
#define T   time
#define PI  3.14159265359
#define PI2 6.28318530718

#define MAX_DIST    150.
#define MIN_DIST    .001

mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0., 1.); }

//@iq shapes and extrude
float box(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.)-.025;
}
float cyl( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}
float opx( in vec3 p, float d, in float h ) {
    vec2 w = vec2( d, abs(p.z) - h );
    return min(max(w.x,w.y),0.) + length(max(w,0.));
}
// gear
float gear(vec3 p, float radius, float thick, float hl) {
    float hole = (radius*.25);
    float sp = floor(radius*PI);
    float gs = length(p.xy)-radius;
    float gw = abs(sin(atan(p.y,p.x)*sp)*.2);
    gs +=smoothstep(.05,.45,gw);
    float cog= hl<1. ? max(opx(p,gs,thick),-(length(p.xy)-hole)) : opx(p,gs,thick);
    return cog;
}
// consts
const float size = 4.;
const float hlf = size/2.;
const float dbl = size*2.;
// globals
float floorspeed;
float ga1,ga2,ga3,ga4;

vec3 hit=vec3(0),hitPoint,gid,sid;
vec3 speed = vec3(0);
mat2 r45,turn,spin;

vec2 map(in vec3 p) {
    vec2 res = vec2(1e5,0.);
    p += speed;

    float id;
    vec3 p2, q;
    for(int i = 0; i<2; i++)
    {
        float cnt = i<1 ? size : dbl;
        q = vec3(p.x-cnt,p.yz);
        id = floor(q.x/dbl) + .5;
        q.x -= (id)*dbl;
        float qf = (id)*dbl + cnt;

        float ff = qf-size;
        float lent= ff<floorspeed-3. ? 7. : clamp(ga4,0.,1.)*7. ;
        float fent= ff<floorspeed-3. ? 5. : clamp(ga4,0.,1.)*5. ;
        vec3 r = q;
        p2=q;
        q.z=abs(q.z)-19.;
        
        float pole = (ff<floorspeed+1.&& i==0) ? min(cyl(q-vec3(0,lent+1.5,0),.25,lent+.5),
        length(q-vec3(0,(lent+1.5)*2.,0))-(.75)) : 1e5;
        
        float pcap = max(cyl(q,.85,1.), -cyl(q,.45,2.) );
        pcap = min(box(q,vec3(1.9,.1,1.5)),pcap);
        pole=min(pcap,pole);
        if(pole<res.x){
            res = vec2(pole,5.);
            hit=q;
            gid = vec3(qf,0,0);
        }  
        
        float qw=q.z - 2.;     
        float wave = .5*sin(qw*1.5-T*4.+ff);
        wave = mix(wave,0.,clamp(1.-((qw-1.5)*.5),0.,.8));
        q.x-= wave*2.;
        q.y-= wave;
        
        vec3 fq = q-vec3(0,(lent*2.),fent);
        float flag=(ff<floorspeed+1.&& i==0) ? box(fq,vec3(.05,2.5,fent)) : 1e5;
        if(flag<res.x){
            res = vec2(flag,1.);
            hit=fq;
            gid = vec3(qf,0,0);
        }

        lent= ff<floorspeed+5. ? 0. : ff>floorspeed+6. ? 3.25 : clamp(1.-ga3,0.,1.)*3.25;
        float ent= ff<floorspeed+35. ? 0. : ff>floorspeed+38. ? 38. : clamp(1.-ga3,0.,1.)*38.;
        
        if(i==0) ent = -ent;
        float d3=box(r-vec3(0,(lent*3.)-2.,ent),vec3(2,2,14.));
        if(d3<res.x){
            res = vec2(d3,3.);
            hit= r-vec3(0,(lent*3.)-2.,ent);
            gid = vec3(qf,0,0);
        }
        
    }

    vec3 pb = vec3(p.x-speed.x-25.,p.y-19.,p.z-11.);
    pb.xy*=spin;
    float bls = gear(pb, 9.,1.5,1.);
    vec3 pp = vec3(p.x-speed.x-29.,p.y-3.,p.z);
    vec3 pq = vec3(p.x-speed.x-16.,p.y-3.,p.z);
    
    float beam = min(length(pp.xy)-.45,length(pq.xy)-.45);
    beam = min(cyl(pb.yzx-vec3(0,22,0),1.25,25.25),beam);
    beam = min(cyl(pb+vec3(0,0,2.4),.5,1.85),beam);
    pp.xy*=turn; pq.xy*=turn;
    bls = min(gear(pp, 3.,14.75,0.),bls);
    bls = min(gear(pq, 3.,14.75,0.),bls);
   
    if(bls<res.x){
        res=vec2(bls,4.);
        hit=p2;
    }
    if(beam<res.x){
        res=vec2(beam,5.);
        hit=pb;
    }
    float fl=max(p.y,-box(p2,vec3(8.,4.,16.)) );
    if(fl<res.x){
        res=vec2(fl,2.);
        hit=p;
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

vec2 marcher(vec3 ro, vec3 rd, int maxsteps){
    float d = 0.;
    float m = 0.;
    for(int i=0;i<maxsteps;i++){
        vec2 ray = map(ro + rd * d);
        if(ray.x<MIN_DIST*d||d>MAX_DIST) break;
        d += i<32?ray.x*.25:ray.x;
        m  = ray.y;
    }
    return vec2(d,m);
}

vec3 hue(float t){ 
    const vec3 c = vec3(.122,.467,.918);
    return .45 + .35*cos(PI2*t*(c+vec3(.878,.969,.851))); 
}

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, inout float d, vec2 uv) {

    vec3 C = vec3(0);
    vec2 ray = marcher(ro,rd,128);
    hitPoint=hit;  
    sid=gid;
    d = ray.x;
    float m = ray.y;
    float alpha = 0.;
    
    if(d<MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        vec3 lpos =vec3(25.,125.,-75.);
        vec3 l = normalize(lpos-p);
        
        vec3 h = vec3(.5);
        vec3 hp = hitPoint+vec3(size,5,size);
        float diff = clamp(dot(n,l),0.,1.);
        float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 9.);
        fresnel = mix(.01, .7, fresnel);

        float shdw = 1.;
        for( float t=.0; t < 38.; ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 18.*h/t);
            t += t<12.? h*.5 : h;
            if( shdw<MIN_DIST || t>38. ) break;
        }

        diff = mix(diff,diff*shdw,.75);

        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec = 0.3 * pow(max(dot(view, ret), 0.), 20.);
        float clr;
        
        // materials
        if(m==1.){
            h=vec3(.745,.933,.929);
            vec2 f = fract(hp.zy)-.5;
            if(f.x*f.y>0.||hp.y<0.) h*=.25;    
            ref = h-fresnel;     
        }
        if(m==2.){
            h=vec3(.192,.306,.302);
            vec2 f = fract(hp.xz/(dbl*2.))-.5;
            if(f.x*f.y>0.) h=vec3(.220,.698,.682);
            if( hp.y<1.1 ) h=vec3(.133,.247,.243);
            ref =(f.x*f.y>0. && hp.y>1.1) ? vec3(.35)-fresnel:vec3(0.); 
        }
        if(m==3.){
            h = hue((50.+sid.x)*.0025);
            float px = .05;
            vec2 grid = fract(hp.xz/hlf)-.5;
            vec2 id = floor(hp.xz/hlf);
            float hs = hash21(id+sid.x);
            if(hs>.5) grid.x*=-1.;
            vec2 d2 = vec2(length(grid-.5), length(grid+.5));
            vec2 gx = d2.x<d2.y? vec2(grid-.5) : vec2(grid+.5);
            float chk = mod(id.y + id.x,2.) * 2. - 1.;
            float circle = length(gx)-.5;
            circle=(chk>.5 ^^ hs<.5) ? smoothstep(-px,px,circle) : smoothstep(px,-px,circle);
            h = mix(h, vec3(.08),circle);
            if(hp.y<6.99) h=vec3(.8); 
            if(hp.y<6.99&&hp.y>6.) h=vec3(.2);
            ref = (h*.4)-fresnel;
        }
        if(m==4.) {
            ref = vec3(.1)-fresnel;
            h=vec3(.2);
        }
        if(m==5.) {
            ref = vec3(.2)-fresnel;
            h=vec3(.4);
        }
        C = (diff*h)+spec;
        ro = p+n*MIN_DIST;
        rd = reflect(rd,n);
    } 
    return vec4(C,alpha);
}

void main(void) {
    vec2 F = gl_FragCoord.xy;

    // precal
    r45=rot(-0.78539816339); 
    float time = (T+40.)*12.;
    float tmod = mod(time, 10.);
    float t3 = lsp(5., 10., tmod);
    
    float fmod = mod(time, 20.);
    float t2 = lsp(10., 20., fmod);
    
    ga1 = (time*.1);
    ga3 = (tmod<5.?t3+1. :t3);
    ga4 = (fmod<10.?t2+1. :t2);
    
    speed = vec3(abs(ga1*size),0,0);
    floorspeed=floor(speed.x);
    turn=rot(ga1);
    spin=rot(-ga1*.38);
    //
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(uv*42.,-42.);
    vec3 rd = vec3(0.,0.,1.);

    ro.yz*=r45;ro.xz*=r45;
    rd.yz*=r45;rd.xz*=r45;
    
    // reflection loop (@BigWings)
    vec3 C = vec3(0), ref=vec3(0), fill=vec3(1);
    float d =0.;

    for(float i=0.; i<2.; i++) {
        vec4 pass = render(ro, rd, ref, d, uv);
        C += pass.rgb*fill;
        fill*=ref;
    }
    // mixdown 
    float vin = length((2.*F.xy-R.xy)/R.x)-.175;
    C = mix(C,C*.5,smoothstep(.0,.8,vin));
    C = clamp(C,vec3(.015),vec3(1));
    // gamma
    C = pow(C, vec3(.4545));
    // output
    glFragColor = vec4(C,1.);
}
//end

