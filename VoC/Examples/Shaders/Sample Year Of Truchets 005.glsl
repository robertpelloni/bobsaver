#version 420

// original https://www.shadertoy.com/view/mtSSRD

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #005
    02/08/2023  @byt3_m3chanic
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI          3.141592653
#define PI2         6.283185307

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21( vec2 p ) { return fract(sin(dot(p+date.z,vec2(23.43,84.21))) *4832.3234); }
float lsp(float b, float e, float t) { return clamp((t - b) / (e-b), 0., 1.); }
float eoc(float t) { return (t = t - 1.) * t * t + 1.; }

//@iq https://iquilezles.org/articles/palettes/
vec3 hue(float t){ 
    return .6+.55*cos(PI2*t+date.z*(vec3(1.,.99,.95)+vec3(0.329,0.851,0.529))); 
}

float tmod=0.,ga1=0.,ga2=0.,ga3=0.,ga4=0.,ga5=0.,ga6=0.,ga7=0.,ga8=0.,lhsh,ghsh;
vec2 lid,gid;
mat2 ry,rx,r1,r2,r3,r4,r5,r6;

#define SCALE 1.
const float scale = 2./SCALE;
const float xf = scale*.5;
const vec2 l = vec2(scale);
const vec2 s = l*2.;
const float sl = l.x*4.;
const vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5),   vec2(.5, -.5), vec2(-.5));

//@iq sdf 
float torus( vec3 p, vec2 a ){
  return length(vec2(length(p.xz)-a.x,p.y))-a.y;
}

float box( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.)) + min(max(q.x,max(q.y,q.z)),0.);
}

float tbox( vec3 p ) {
    vec2 d2 = vec2(length(p.xz-xf), length(p.xz+xf));
    vec2 gx = d2.x<d2.y ? vec2(p.xz-xf) : vec2(p.xz+xf);
    vec3 pv = vec3(gx.x,p.y,gx.y);
    float d = torus(pv,vec2(xf,.2));
    float b = box(p,vec3(xf));
    d=max(abs(d)-.085,-d);
    d=max(d,b);
    return d;
}
float flt( vec3 p ) {
    float d = min(length(p.yz)-.2,length(p.yx)-.2);
    float b = box(p,vec3(xf));
    d=max(abs(d)-.085,-d);
    d=max(d,b);
    return d;
}
vec2 map(vec3 p) {
    vec2 res =vec2(1e5,0.);

    mat2 rz = rot((ga7-ga8)*PI);
    p.xz*=rz;

    vec2 r,ip,ct = vec2(0);

    //@Shane - multi tap grid
    for(int i =0; i<4; i++){
        ct = ps4[i]/2.;              // Block center.
        r = p.xz - ct*s;             // Local coordinates. 
        ip = floor(r/s) + .5;        // Local tile ID. 
        r -= (ip)*s;                 // New local position.   
        vec2 idi = (ip*s) + ct;
 
        float hs = hash21(idi);
        
        vec3 q = vec3(r.x,p.y,r.y);
        
        float chx = mod(idi.x,2.) * 2. - 1.;
        float chy = mod(idi.y,2.) * 2. - 1.;
        
        float chk = (chy<1. ^^ chx<1.) ? 1. : .0;
        
        if(chk>.5) { 
            q.xz*=r1; 
            q.xy*=r5;
            q.xy*=r3;
        } else { 
            q.xz*=r2; 
            q.xy*=r4;
            q.xy*=r6;
        }

        if(hs>.5) q.z*=-1.;
        
        float frame2 = (hs>.8) ? flt(q):tbox(q);
        if(frame2<res.x) {
            float nf = fract(hs*32.);
            lid=idi;
            lhsh=hs;
            res = vec2(frame2,nf<.175?4.:2.);
        }

    }
    
    float ff = p.y+2.;
        if(ff<res.x) {
        res = vec2(ff,1.);
    }
        
    return res;
}

//Tetrahedron technique
//https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = t;
    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec3 render(vec3 p, vec3 rd, vec3 ro, float d, float m, inout vec3 n, inout float fresnel) {
    n = normal(p,d);
    vec3 lpos =  vec3(8,5,0);
    vec3 l = normalize(lpos-p);
    float diff = clamp(dot(n,l),0.,1.);

    vec3 h=vec3(.01);
    if(m==1.) {
        //p.xz-=T*vec2(.5,-.5);
        vec2 id = floor(p.xz*1.25);
        vec2 uv = fract(p.xz*1.25)-.5;
        float hs = hash21(id);
        if(hs>.5) uv.x*=-1.;
        
        float px = 10./R.x;
        
        vec2 d2 = vec2(length(uv-.5), length(uv+.5));
        vec2 nv = d2.x<d2.y? vec2(uv-.5) : vec2(uv+.5);
        float d = length(nv)-.5;
        d=smoothstep(px,-px,abs(abs(d)-.2)-.075);
        h=mix(h,vec3(.075),d);
        
    } else {
        h = m==2. ? hue(ghsh*.3) : vec3(.075);
    }
    
    return diff*h;
}

float zoom = 7.;
void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
	vec2 F = gl_FragCoord.xy;	

    // precal
    float time = T;
    
    float x = 0;//M.xy == vec2(0) ? 0. : -(M.y/R.y * 3. - 1.5) * PI;
    float y = 0;//M.xy == vec2(0) ? 0. : -(M.x/R.x * 1. - .5) * PI;
    
    zoom = 7.-x;
    
    tmod = mod(time, 16.);
    float t1 = lsp(2.0, 4.0, tmod);
    float t2 = lsp(10.0, 12.0, tmod);
    float t3 = lsp(4.0, 8.0, tmod);
    float t4 = lsp(5.0, 8.0, tmod);
    float t5 = lsp(13.0, 15.0, tmod);
    float t6 = lsp(8.0, 10.0, tmod);
    float t7 = lsp(7.0, 11.0, tmod);
    float t8 = lsp(1.0, 5.0, tmod);
    
    ga1 = eoc(t1);
    ga1 = ga1*ga1*ga1;

    ga2 = eoc(t2);
    ga2 = ga2*ga2*ga2;
    
    ga3 = eoc(t3);
    ga3 = ga3*ga3*ga3;
    
    ga4 = eoc(t4);
    ga4 = ga4*ga4*ga4;
    
    ga5 = eoc(t5);
    ga5 = ga5*ga5*ga5;
    
    ga6 = eoc(t6);
    ga6 = ga6*ga6*ga6;
    
    ga7 = eoc(t7);
    ga7 = ga7*ga7*ga7;
    
    ga8 = eoc(t8);
    ga8 = ga8*ga8*ga8;

    r1=rot(ga1*PI); 
    r2=rot(ga2*PI); 
    r3=rot(ga3*PI);
    r4=rot(ga4*PI);
    r5=rot(ga5*PI);
    r6=rot(ga6*PI);
            
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);

    //orthographic camera
    vec3 ro = vec3(uv*zoom,-zoom-5.);
    vec3 rd = vec3(0,0,1.);

    rx = rot(.615);
    ry = rot(-.785+y);
    
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;

    vec3 C = vec3(.0);
    vec3  p = ro + rd;
    float atten = .95;
    
    float k = 1.,d = 0.,b = 4.;
    
    for(int i=0;i<80;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float m = ray.y;

        d = i<32 ? ray.x*.5 : ray.x;
        p += rd * d *k;
        
        gid=lid;
        ghsh=lhsh;
            
        if (d*d < 1e-6) {
  
            float fresnel=0.;
            C+=render(p,rd,ro,d,ray.y,n,fresnel)*atten;
            b--;
            
            if(m==1.||b<0.) break;
            
            atten *= ray.y==4.?.95:.65;
            p += rd*.01;
            k = sign(map(p).x);

            vec3 rr = vec3(0);
            
            if(m==2.) {
                rd=reflect(-rd,n);
                p+=n*.035;
                b-=2.;
            } else {
                rr = refract(rd,n,.55);
                rd=mix(rr,rd,.5-fresnel);
            }

        } 
       
        if(distance(p,rd)>35.) { break; }
    }

    if(C.r<.008&&C.g<.008&&C.b<.008) C = hash21(uv)>.85 ? C+.015 : C;
    C = pow(C, vec3(.4545));
    glFragColor = vec4(C*vec3(0.494,0.655,0.827),1.0);
}
