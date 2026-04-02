#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R         resolution
#define T         time
#define M         mouse

#define PI              3.14159265358
#define PI2             6.28318530718

#define MAX_DIST    100.
#define MIN_DIST    .001
// Hash
float hash21(vec2 p) 
{  
return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); 
}
mat2 rot(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float vmax(vec3 p)
{
    return max(max(p.x,p.y),p.z);
}

float box(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}

float torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xy)-t.x,p.z);
  return length(q)-t.y;
}

vec3 hp,hitPoint;
mat2 rt;

vec2 map(vec3 p)
{
    vec2 res = vec2(1e5,0.);
    vec3 q = p+vec3(0,0,1);
    vec3 q3=q;
    
    float bf = box(q3,vec3(55., 35.0, 25.));
    float cx = box(q3,vec3(8.35,5.25, 60.));
    bf = max(bf,-cx );
    
    if(bf<res.x) {
        res = vec2(bf,1.);
        hp=q3;
    }
    
    //spheres
    float qd = floor((q3.z+1.5)/3.);
    q3.z=mod(q3.z+1.5,3.)-1.5;
    
    float rdx = .65+.2*sin(qd+T*1.25);
    float ddx = (rdx*2.)-1.;
    float b = length(q3-vec3(0,(rdx*.5)+ddx,0))-rdx;
    if(b<res.x) {
        res = vec2(b,2.);
        hp=q;
    }
    //boxes
    vec3 qr = q-vec3(4.-rdx,1.5-ddx,0);
    float id = floor((qr.z+1.5)/3.);
    qr.xy*=rot(T*.3+id*.1);
   
    qr.z=mod(qr.z+1.5,3.)-1.5;
    qr.zx*=rot(T*.5+id*.2);
     
    float bx = box(qr,vec3(.75,.05,.75));
    if(bx<res.x) {
        res = vec2(bx,2.);
        hp=q;
    }
    //rings
    vec3 nq = q+vec3(4.05,-.35,0);
    float nd = floor((nq.z+1.5)/3.);
    nq.z=mod(nq.z+1.5,3.)-1.5;
    mat2 rota =rot(T*.3+ddx);
    mat2 rotb =rot(T*.2+nd*.5);
    
    nq.yz*=rota;
    nq.xz*=rotb;
    float tr = torus(nq,vec2(.95,.15));
    nq.yz*=rota;
    nq.xz*=rotb;
    tr = min(tr, torus(nq,vec2(.45,.15)) );
    if(tr<res.x) {
        res = vec2(tr,2.);
        hp=q;
    }
    //floor
    float f = p.y+1.;
    if(f<res.x) {
        res = vec2(f,1.);
        hp=p;
    }

    return res;
}

vec3 normal(vec3 p, float t)
{
    t*=MIN_DIST;
    float d = map(p).x;
    
    vec2 e = vec2(t,0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x
        );
    return normalize(n);
}

const vec3 c = vec3(0.959,0.970,0.989),
           d = vec3(0.651,0.376,0.984);
           
vec3 hue(float t){ 
    return .5 + .45*cos(13.+PI2*t*(c*d) ); 
}

void main()
{
    rt = rot(T*.5);
    vec3 C,
         FC = vec3(0.800,0.792,0.659);

    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    
    vec3 ro = vec3(0,0,4.25),
         rd = normalize(vec3(uv,-1));

    mat2 r2 = rot(.25+.25*sin(T*.4));
    mat2 r1 = rot(.3+.3*cos(T*.3));
    
    ro.yz*=r2;
    rd.yz*=r2;
    ro.xz*=r1;
    rd.xz*=r1;
    
    float d = 0.01, m = 0.;
    float bnc = 0.;
    vec3 p = ro + rd;
    //ray marcher
    for(int i=0;i<196;i++)
    {
        vec2 ray = map(p);
        d += ray.x;
        m = ray.y;
        p += rd * ray.x * .76;
        if(d>MAX_DIST)break;
        
        if(abs(ray.x)< .0005)
        {
            if(m ==2. && bnc<4.)
            {
                bnc+=1.;
                rd = reflect(rd,normal(p,d));
                p +=rd*.001;
            } 
        }
    }
    
    hitPoint=hp;
    // draw on screen
    if(d<MAX_DIST)
    {
        vec3 n = normal(p,d);
 
        vec4 h = vec4(.5);
        if(m==1.)
        {
            hitPoint.z-=T*1.5;
            hitPoint*=.45;
            vec3 id=floor(hitPoint)-.5;
            vec3 f= fract(hitPoint)-.5;
            vec3 clr = hue(hash21(id.xz)*3.2);
            h = f.x*f.y*f.z>0. ? vec4(clr,24.) : vec4(.5,.5,.5,14.);
        
        }
        if(m==3.) h.rgb=hue(14.);
        
        vec3 lpos = vec3(3.*sin(T*.4),3,5);
        vec3 l = normalize(lpos-p);
 
        // shading and shadow
        float diff = clamp(dot(n,l),0.,1.);
        float shadow = 0.;
        for(int i=0;i<64;i++)
        {
            vec3 q = (p + n * .2) + l * shadow;
            float h = map(q).x;
            if(h<MIN_DIST*d||shadow>MAX_DIST)break;
            shadow += h;
        }
        
        if(shadow < length(p -  lpos)) diff *= .1;

        //specular 
        vec3 view = normalize(p - ro);
        vec3 ref = reflect(normalize(lpos), n);
        float spec =  0.75 * pow(max(dot(view, ref), 0.), h.w);

        C += h.rgb * diff + spec;
  
    }

    C = mix( C, FC, 1.-exp(-.0000725*d*d*d));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
