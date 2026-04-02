#version 420

// original https://www.shadertoy.com/view/XttSW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define CROSSEYE 0.2

#define STEPS 10.
#define ORTHOGONAL
#define SURFACE
#define MESH vec4(vec3(0),0.01)

#define PI  3.14159
#define TAU 6.28318
#define T   time

const float U_MIN = 0.0;
const float U_MAX = TAU;
const float V_MIN = 0.0;
const float V_MAX = TAU;

// Your equation here

vec3 fn(float u, float v)
{
    // Torus:  return vec3(cos(u)*(1.-cos(v)*0.5),sin(v)*0.5,sin(u)*(1.-cos(v)*0.5));
    // Sphere: return vec3(sin(u)*cos(v),sin(v),cos(u)*cos(v) );
    // Cone:   return vec3(sin(u),1,cos(u))*sin(v);
    // Plane:  return vec3(u-PI,1,v-PI)*0.5;
    // Vase:   return vec3(cos(u),(v-PI)/TAU*3.,sin(u))*vec2((1.-cos(v-PI*1.5)*0.5)*step(0.01,v),1).xyx*0.7;
    
    // Klein Bottle:
    // (from https://de.wikipedia.org/wiki/Kleinsche_Flasche#Beschreibung_im_3-dimensionalen_Raum)
    
    float r = 2.0-cos(u);

    return vec3(
        2.0*(1.0-sin(u))*cos(u)+r*cos(v)*(2.0*exp(-pow(u/2.0-PI,2.0))-1.0),
        r*sin(v),
        6.0*sin(u) + 0.5*r*sin(u)*cos(v)*exp(-pow(u-3.0*PI/2.0,2.0))
    ).xzy*0.2;
}

/* -------------------------------------------------------------------------------------------------------- */

const float U_STP = (U_MAX-U_MIN)/STEPS;
const float V_STP = (V_MAX-V_MIN)/STEPS;

struct Ray    { vec3 o, d; };
struct Camera { vec3 p, t; };
struct Hit    { vec3 p, n; float t; int id; };
    
Camera _cam = Camera(vec3(0,0,-2.5), vec3(0));
Hit _miss   = Hit(vec3(0),vec3(0),-1e10, 0);

mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
bool isNan(float val){return(val<=0.||0.<=val)?false:true;}

Hit triangle(Ray r, vec3 a, vec3 b, vec3 c, int id)
{
    vec3 ab = b-a, bc = c-b, ac = c-a;
    vec3 n = cross(ab,ac);

    float nrd = dot(n,r.d);
    if (abs(nrd) < 0.001 || isNan(nrd) == true) { return _miss; }

    float t = -dot(n,r.o-a)/nrd;
    if (t < 0.0) { return _miss; }

    vec3 p = r.o+r.d*t;

    if(dot(n,cross( ab,p-a)) < 0.0
    || dot(n,cross( bc,p-b)) < 0.0
    || dot(n,cross(-ac,p-c)) < 0.0) { return _miss; }
    
    return Hit(b+bc/2.,vec3(sign(nrd)),t,id);
}

// Can probably be simpilfied a lot
Hit line(Ray r, vec3 pa, vec3 pb, float sr, int id)
{
    vec3 ab = pb-pa;
    vec3 oa = pa-r.o;
    
    float dabrd = dot(ab,r.d);
    float drdrd = dot(r.d,r.d);
    
    float det = dot(ab,ab)*drdrd-dot(ab,r.d)*dabrd;
    if (det == 0.) { return _miss; }

    vec3 sp = pa+ab*clamp((dot(oa,r.d)*dabrd-dot(oa,ab)*drdrd)/det,0.,1.);

    r.o -= sp;

    float a = drdrd;
    float b = 2.0*dot(r.o,r.d);
    float c = dot(r.o,r.o)-sr*sr;
    float d = pow(b,2.0)-4.0*a*c;

    if (d < 0.0) { return _miss; }
    
    float s = sqrt(d);
    float t = min(-b+s,-b-s)/(2.*a);
    
    return Hit(vec3(0), vec3(0), t, id);

    // vec3 p = r.o+sp+r.d*t;
    // vec3 n = normalize(p-sp);
    
    // return Hit(p, n, t, id);
}

float compare(inout Hit a, Hit b)
{
    if (a.t < 0.0 || b.t > 0.0 && b.t < a.t)
    {
        a = b;
        return 1.0;
    }
    
    return 0.0;
}

Hit trace(Ray r)
{
    Hit h = _miss;
    
    for(float u = U_MIN; u < U_MAX; u += U_STP)
    {          
        for(float v = V_MIN; v < V_MAX; v += V_STP)
        {        
            vec3 a = fn(u,v);
            vec3 b = fn(u,v+V_STP);
            vec3 c = fn(u+U_STP,v);

            #ifdef MESH
            
                compare(h,line(r,a,b,MESH.w,0));
                compare(h,line(r,a,c,MESH.w,0));
            
            #endif

            #ifdef SURFACE
                
                vec3 d = fn(u+U_STP,v+V_STP);
            
                float comp = max(
                    compare(h,triangle(r,a,b,c,1)),
                    compare(h,triangle(r,d,c,b,1))
                );

                if (comp > 0.0)
                {
                    h.n = normalize(cross(a-b,d-b))*h.n.x;
                }

            #endif
        }
    }

    return h;
}

Ray lookAt(Camera cam, vec2 uv)
{
    vec3 d = normalize(cam.t-cam.p);
    vec3 r = normalize(cross(d,vec3(0,1,0)));
    vec3 u = cross(r,d);
    
    #ifndef ORTHOGONAL
    return Ray(cam.p,normalize(r*uv.x + u*uv.y + d));
    #else
    return Ray(cam.p+(r*uv.x + u*uv.y)*2.0, d);
    #endif
}

vec3 getColor(Hit h)
{
    if(h.t <= 0.0) { return vec3(0.2); }
    
    #ifdef MESH
    if(h.id == 0) { return MESH.rgb; }
    #endif
    
    // float diff = max(dot(normalize(_cam.p-h.p),h.n),0.5);
    // float spec = pow(max(dot(reflect(normalize(h.p-_cam.p),h.n),normalize(_cam.p-h.p)),0.0),100.);
    
    return normalize(h.n+1.0);
}

void main(void)
{
    // normalized screen and mouse coordinates
    vec2 uv  = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.yy;
    vec2 uvm = (2.0 * mouse*resolution.xy.xy    - resolution.xy) / resolution.xy;
    
    uvm = vec2(T*0.1+PI/2.1, 0.4); 
    
    #ifdef CROSSEYE
    _cam.p.x += sign(uv.x)*CROSSEYE;
    uv.x = mod(uv.x,1.5)-1.5/2.;
    #endif
    
    // cam rotation
    _cam.p.yz *= rot(uvm.y*PI/2.);
    _cam.p.xz *= rot(uvm.x*TAU);
    
    // vignette
    float f = 1.-length((2.0*gl_FragCoord.xy-resolution.xy)/resolution.xy)*0.25;
    
    glFragColor = vec4(getColor(trace(lookAt(_cam,uv))),1)*f;
}
