#version 420

// original https://www.shadertoy.com/view/ctKSz3

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #035
    06/12/2023  @byt3_m3chanic
    Truchet Core \M/->.<-\M/ 2023 
    
    Square truchet with offset to match corner roundness 
    
*/

//if slow turn AA off 1 
#define ZERO (min(frames,0))
#define AA 1

#define R           resolution
#define T           time
#define M           mouse*resolution.xy

#define PI          3.14159265359
#define PI2         6.28318530718

#define MIN_DIST    .001
#define MAX_DIST    45.

vec3 hp,hitpoint;
float gid,sid,speed,tspd;
mat2 r90,rta;

mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }
//@iq
float box(vec2 p, vec2 b) { vec2 d = abs(p)-b; return length(max(d,0.)) + min(max(d.x,d.y),0.);}
float opx(in float d, in float z, in float h){
    vec2 w = vec2(d,abs(z)-h);return min(max(w.x, w.y),0.)+length(max(w,0.));
}

const float sz = 8.5;
const float hf = 4.25;
const float scale = .1;

vec2 map(vec3 p) {
    vec2 res = vec2(1e5,0);
    
    //@mla inversion
    float k = 8./dot(p,p); 
    p *= k;
    
    p.y += speed;
    vec3 pp = p;
    
    float pid = floor((p.y+hf)/sz);
    p.y = mod(p.y+hf,sz)-hf;

    p.xz*=rot(tspd+(pid*.234));
    pp.xz = p.xz;
    
    vec2 id = floor(p.xz*scale), q = fract(p.xz*scale)-.5;
    float hs = hash21(id.xy+pid);
    if(hs>.5)  q.xy *= r90;
    
    hs = fract(hs*575.3+pid);
    const float pf = .45,wd = .1;
    
    vec2 p2 = vec2(length(q.xy-pf),length(q.xy+pf));
    vec2 r = p2.x<p2.y? q.xy-pf : q.yx+pf;
    
    // patterns
    float d = abs(box(r,vec2(.15))-.3)-wd;
    float d1 = 1e5, d2=1e5, d3=1e5;
    
    p.y *= scale;
    
    if(hs>.75) {
        d2 = length(q.x)-wd;
        d = length(q.y)-wd;
        
        float ff = .125*cos(q.y*PI2)+.125;
        float py = fract(hs*37.72)>.65? p.y-ff : p.y+ff;
        d3 = opx(d2,py,wd);
    } else if(hs<.25) {
        d = length(q.x)-wd;
        d = min(length(abs(q.xy)-vec2(.5,0))-wd,d);
    }

    d1 = opx(d,p.y,wd);
    
    if(d1<res.x) {
        res = vec2(d1,2.);
        hp = pp;
    }
   
    if(d3<res.x) {
        res = vec2(d3,2.);
        hp = pp;
    }
    
    // compensate for scaling and warp
    res.x /= scale;
    res.x *= 1./k;
    return res;
}

// Tetrahedron technique @iq
// https://iquilezles.org/articles/normalsSDF
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h =vec2(1,-1)*.5773;
    vec3 n = h.xyy * map(p+h.xyy*e).x+
             h.yyx * map(p+h.yyx*e).x+
             h.yxy * map(p+h.yxy*e).x+
             h.xxx * map(p+h.xxx*e).x;
    return normalize(n);
}

vec2 marcher(vec3 ro, vec3 rd, inout vec3 p, inout bool hit) {
    hit = false; float d=0., m = 0.;
    for(int i=0;i<80;i++)
    {
        vec2 t = map(p);
        if(t.x<MIN_DIST) hit = true;
        d += i<45? t.x*.3 : t.x;
        m  = t.y;
        p = ro + rd * d;
        if(d>MAX_DIST) break;
    } 
    return vec2(d,m);
}

//@iq hsv2rgb
vec3 hsv2rgb( in vec3 c ) {
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0,4,2),6.)-3.)-1., 0., 1. );
    return c.z * mix( vec3(1), rgb, c.y);
}

vec3 render(inout vec3 ro, inout vec3 rd, inout float d) {
        
    vec3 RC = vec3(0), p = ro;
    float m = 0.;
    bool hit = false;
    
    vec2 ray = marcher(ro,rd,p,hit);
    d = ray.x;
    m = ray.y;
    hitpoint = hp;

    if(hit)
    {
        vec3 n = normal(p,d);
        vec3 l = normalize(vec3(.2,8,.2)-p);
        float diff = clamp(dot(n,l),0.,1.);

        float shdw = 1.;
        for( float t=.01; t < 12.; ) {
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 12.*h/t);
            t += h;
            if( shdw<MIN_DIST ) break;
        }
        diff = mix(diff,diff*shdw,.65);

        float spec = .75*pow(max(dot(normalize(p-ro),reflect(l,n)),0.),5.);
        vec3 h = hsv2rgb(vec3(hitpoint.y*.01,1.,.5));
        RC = h * diff+min(shdw,spec);
    } 
    return RC;
}

mat2 rx,ry;

const vec3 FC = vec3(.012,.098,.188);
// AA from @iq https://www.shadertoy.com/view/3lsSzf
void main(void) //WARNING - variables void ( out vec4 O, in vec2 F ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 F = gl_FragCoord.xy;

    speed=T*.7;
    r90=rot(1.5707);
    tspd=T*.012*PI2;
    
    // mouse
    float x = 0.;//M.xy==vec2(0) || M.z<0. ? 0. : -(M.y/R.y*.25-.125)*PI;
    float y = 0.;//M.xy==vec2(0) || M.z<0. ? 0. : -(M.x/R.x*1.-.5)*PI;
 
    rx =rot(-x-1.5707);
    ry =rot(-y);
    
    vec3 C = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 uv = (-R.xy + 2.0*(F+o))/max(R.x,R.y);
#else    
        vec2 uv = (-R.xy + 2.0*F)/max(R.x,R.y);
#endif

        // ro + rd
        vec3 ro = vec3(0,0,1.);
        vec3 rd = normalize(vec3(uv,-1));

        ro.zy*=rx;rd.zy*=rx;
        ro.xz*=ry;rd.xz*=ry;

        float d = 0.;

        vec3 color = render(ro,rd,d);
        color = mix(FC,color,exp(-2.5*d*d*d));
        
        // compress        
        color = 1.35*color/(1.0+color);
        // gamma
        color = pow( color, vec3(0.4545) );

        C += color;

#if AA>1
    }
    C /= float(AA*AA);
#endif
    // Output to screen
    glFragColor = vec4(C,1.);
}
//end