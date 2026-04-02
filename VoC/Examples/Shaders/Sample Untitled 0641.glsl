#version 420

// original https://www.shadertoy.com/view/7dlSz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**daily shader | 004 4/15/2012 @byt3_m3chanic*/

#define R               resolution
#define T               time
#define M               mouse*resolution.xy

#define PI            3.14159265358
#define PI2           6.28318530718

#define MAX_DIST      100.
#define MIN_DIST      .001

float hash21(vec2 p)
{
    return fract(sin(dot(p,vec2(23.86,48.32)))*4374.432);
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

float cone( vec3 p, vec2 c, float h )
{//@iq sdf functions
  p.y-=.75;
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}

vec3 hp,hitPoint;
vec3 vid,mxId;
float ga1,ga2,ga3,ga4,ga5,ga6,ga7;
mat2 rx1,rx2,rx3;

vec2 map(vec3 p)
{
    vec2 res = vec2(1e5,0.);
    vec3 q = p+vec3(0,0,0);
    vid = floor((q+6.)/12.);
    q.xz = mod(q.xz+6.,12.)-6.;
    float b1 = length(q+vec3(0,0,3.05))-.85;
    float b2 = box(q+vec3(0,0,3.05),vec3(.75));
    float b=mix(b1,b2,ga1);
    if(b<res.x) {
        res = vec2(b,2.);
        hp=q;
    }

    vec3 q2 = q-vec3(3.0,0,0);
    q2.yz*=rx2;
    q2.xz*=rx3;
    float bx1 = box(q2,vec3(.75));
    float bx2 = torus(q2,vec2(.75,.15));
    float bx=mix(bx1,bx2,ga2);
    if(bx<res.x) {
        res = vec2(bx,3.);
        hp=q;
    }
    

    vec3 q3 = q+vec3(3.05,0,0);
    q3.yz*=rx1;
    float tr1 = cone(q3,vec2(.75,.35),1.25);
    float tr2 = length(q3)-.85;
    float tr=mix(tr1,tr2,ga3);
    if(tr<res.x) {
        res = vec2(tr,3.);
        hp=q;
    }
    
    float tg1 = torus(q,vec2(.75,.15));
    float tg2 = length(q)-.85;;
    float tg=mix(tg1,tg2,ga4);
    if(tg<res.x) {
        res = vec2(tg,4.);
        hp=q;
    }
    
    vec3 q5 = q-vec3(.0,0,3.);
    q5.yz*=rx2;
    q5.xz*=rx1;
    float bz1 = box(q5,vec3(.75));
    float bz2 = cone(q5,vec2(.75,.35),1.25);
    float bz=mix(bz1,bz2,clamp(ga1+ga4,0.,1.));
    if(bz<res.x) {
        res = vec2(bz,2.);
        hp=q;
    }
    
    float f = p.y+1.;
    if(f<res.x) {
        res = vec2(f,1.);
        hp=p;
    }
    return res;
}

vec2 marcher(vec3 ro, vec3 rd, int steps)
{
    float d,m;
    for(int i = 0; i<steps;i++)
    {
        vec2 ray = map(ro+rd*d);
        if(ray.x<d*MIN_DIST||d>MAX_DIST)break;
        d += ray.x;
        m  = ray.y;
    
    }
    return vec2(d,m);
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
           d = vec3(0.067,0.910,0.702);
vec3 hue(float t){ 
    return .55 + .45*cos( 13.+PI2*t*(c*d) ); 
}
//grid amount 
const float gd = 5.;
void debug(vec2 uv, inout vec3 C)
{
    vec2 cc = vec2(0,1);
    float px = fwidth(uv.x)*PI2;
    vec2 id=floor(uv*gd);
    C=min(C,hue(hash21(id)));
    uv=fract(uv*gd);
    if(uv.x>-px&&uv.x<px) C = cc.xxx;
    if(uv.y>-px&&uv.y<px) C = cc.xxx;
}
// Book Of Shaders - timing functions
float linearstep(float begin, float end, float t) 
{
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

float easeOut(float t) 
{
    return (t = t - 1.0) * t * t + 1.0;
}

float easeIn(float t) 
{
    return t * t * t;
}

void main(void)
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;

    float tm = mod(time*2.3, 11.);
    // any tips on doing better timing stuff?
    float a1 = linearstep(0.0, 2.0, tm);
    float a2 = linearstep(4.0, 5.0, tm);
    float t1 = easeIn(a1);
    float t2 = easeOut(a2);
    
    float a3 = linearstep(2.0, 3.0, tm);
    float a4 = linearstep(6.0, 7.0, tm);
    float t3 = easeIn(a3);
    float t4 = easeOut(a4);

    float a5 = linearstep(4.0, 5.0, tm);
    float a6 = linearstep(8.0, 9.0, tm);
    float t5 = easeIn(a5);
    float t6 = easeOut(a6);
    
    float a7 = linearstep(6.0, 7.0, tm);
    float a8 = linearstep(10.0, 11.0, tm);
    float t7 = easeIn(a7);
    float t8 = easeOut(a8);
    
    ga1 = t1-t2;
    ga2 = t3-t4;
    ga3 = t5-t6;
    ga4 = t7-t8;

    rx1=rot(ga1);
    rx2=rot(ga2);
    rx3=rot(ga2);
    
    vec3 C,
         FC = vec3(0.329,0.337,0.427);

    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec2 suv = uv;
    vec2 id = floor(suv*gd);
    float hs = hash21(id)*10.;
    vec4 checkcolor = vec4(.1,.2,.5,24.);

    if(hs>6.) checkcolor = vec4(hue(34.),24.);
    if(hs>7.) uv.x+=.025+.025*sin(uv.y*12.3+T*6.4);

    vec3 ro = vec3(0,-.95,4.5),
         rd = normalize(vec3(uv,-.75));

    mat2 turn = rot(T*.2);
    mat2 down = rot(.625);
    ro.yz*=down;
    rd.yz*=down;
    ro.xz*=turn;
    rd.xz*=turn;
    
    vec2 ray = marcher(ro,rd,164);
    hitPoint=hp;
    mxId=vid;
    float d = ray.x;
    float m = ray.y;

    if(d<MAX_DIST)
    {
        vec3 p = ro+rd*d;
        vec3 n = normal(p,d);
 
        vec4 h = vec4(.5);
        if(m==1.)
        {
            hitPoint.z-=T*1.5;
            vec2 f=fract(hitPoint.xz*.25)-0.5;
            h = f.x*f.y>0. ? checkcolor : vec4(.001,.001,.001,24.);
        
        }
        float zff = abs(vid.x+vid.z)*.52;
        if(m==2.) h = vec4(hue(23.+zff), 32.);
        if(m==3.) h = vec4(hue(45.+zff), 48.);
        if(m==4.) h = vec4(hue(21.+zff), 64.);
        
        vec3 lpos = vec3(-12.,5,7);
        vec3 l = normalize(lpos-p);
        l.xz*=turn;
 
        // shading and shadow
        float diff = clamp(dot(n,l),0.,1.);
        float shd = marcher(p+n*(MIN_DIST*2.), l, 92).x; 
        if(shd<length(lpos-p)) diff *= .1;
        
        //specular 
        vec3 view = normalize(p - ro);
        vec3 ref = reflect(normalize(lpos), n);
        float spec =  0.75 * pow(max(dot(view, ref), 0.), h.w);

        C += h.rgb * diff + spec;

    }

    C = mix( C, FC, 1.-exp(-.00025*d*d*d));
    debug(suv,C);
    O = vec4(pow(C, vec3(0.4545)),1.0);

    glFragColor=O;
}
