#version 420

// original https://www.shadertoy.com/view/tsSfWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * Fly With Me-Happy Together
 * By Ayquo 2020
 */

#define MAX_STEPS                     250
#define MAX_DIST                     200.
#define SURF_DIST                     .001
#define STEP_FACTOR                 .40
#define t                             ((time*5.)+52.4)
#define FLUTTER_FREQ                 35.

#define COLOR_TEAL                     (vec3(0.,   175., 210.)/255.)
#define COLOR_ORANGE                 (vec3(210., 140.,   0.)/255.)
#define COLOR_RED                     (vec3(210.,   0.,  70.)/255.)
#define COLOR_PURPLE                 (vec3(128.,   0., 255.)/255.)

#define BUTTERFLY_1_COLORINDEX_1     0
#define BUTTERFLY_1_COLORINDEX_2     1
#define BUTTERFLY_2_COLORINDEX_1    2
#define BUTTERFLY_2_COLORINDEX_2    3

#define BUTTERFLY_1_COLOR_1         COLOR_RED
#define BUTTERFLY_1_COLOR_2         COLOR_TEAL
#define BUTTERFLY_2_COLOR_1         COLOR_ORANGE
#define BUTTERFLY_2_COLOR_2         COLOR_PURPLE

/* Base: "RayMarching starting point" by BigWings https://www.shadertoy.com/view/WtGXDD */
mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

/* Iq https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm */
float sdEllipsoid(vec3 p,vec3 r)
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float sdSphere(vec3 p,float r)
{
    return length(p)-r;
}

float sdBox(vec3 p,vec3 s) {
    p = abs(p)-s;
    return length(max(p,0.))+min(max(p.x,max(p.y,p.z)),0.);
}

/* https://github.com/glslify/glsl-look-at/blob/gh-pages/index.glsl */
mat3 calcLookAtMatrix(vec3 origin,vec3 target,float roll) 
{
  vec3 rr = vec3(sin(roll),cos(roll),0.0);
  vec3 ww = normalize(target-origin);
  vec3 uu = normalize(cross(ww,rr));
  vec3 vv = normalize(cross(uu,ww));
  return mat3(uu,vv,ww);
}

/* Butterfly SDF by Ayquo 2020 */
float sdButterfly(vec3 p,out int colorIndex)
{    
    // Mirror space
    p.x = abs(p.x); 
    
    /* Body */
    float butterfly = sdEllipsoid(p+vec3(0,0,.1),vec3(.15,.15,.6));
    
    /* Antenna */
    // Rotate space for antenna
    vec3 pr = p;
    pr.xz *= Rot(-.2);
    butterfly = min(butterfly,sdEllipsoid(pr+vec3(0.1,0,1.),vec3(.05,.05,.5)));
    
    /* Front wing */
    // Rotate space for front wing flutter
    pr = p;
    pr.xy *= Rot(sin(time*FLUTTER_FREQ));

    // Front wing
    vec3 pp = pr+vec3(-.9,0,0.7);
    pp.xz *= Rot(.7);
    float wing = sdEllipsoid(pp,vec3(1.,.1,.5));
    wing = max(wing,-sdEllipsoid(pp,vec3(1.,.5,.5)*.75));
    // Inner front wing
    float innerFrontWing = sdEllipsoid(pp,vec3(1.,.1,.5)*.5);
    
    // Front wing bridge
    pp = pr+vec3(-.95,0,0.7)*.5;
    pp.xz *= Rot(.7);
    wing = min(wing,sdEllipsoid(pp,vec3(1.,.25,.1)*.75));
    butterfly = min(butterfly,wing);
    
    /* Back wing */
    // Rotate space for back wing flutter
    pr = p;
    pr.xy *= Rot(-cos(time*FLUTTER_FREQ));    

    // Back wing
    pp = pr+vec3(-.7,0,-0.5);
    pp.xz *= Rot(-.7);
    
    wing = sdEllipsoid(pp,vec3(1.,.1,.5)*.75);
    wing = max(wing,-sdEllipsoid(pp,vec3(1.,.5,.5)*.75*.75));
    butterfly = min(butterfly,wing);
    // Inner back wing
    float innerBackWing = sdEllipsoid(pp,vec3(1.,.1,.5)*.35);

    // Back wing bridge
    pp = pr+vec3(-.8,0,-0.5)*.5;
    pp.xz *= Rot(-.7);
    wing = min(wing,sdEllipsoid(pp,vec3(1.,.25,.1)*.5));
    butterfly = min(butterfly,wing);
    
    // Decide which color and distance to return
    if (butterfly < min(innerFrontWing,innerBackWing)) {
        colorIndex = 0;    
        return butterfly;        
    } else {
        colorIndex = 1;    
        return (innerFrontWing<innerBackWing)?innerFrontWing:innerBackWing;
    }
}

vec3 getPosFromOffset(vec3 p,float off)
{
    p.x+= sin(off)-sin(off*.834)-sin(off*.255)-sin(off*.184)-sin(off*1.179)+sin(off*.346);
    p.y+= cos(off)-cos(off*.345)-cos(off*.598)-cos(off*.253)-cos(off*1.179)+cos(off*.346);
    return p;
}

float getButterflyFromPos(vec3 p,out int colorIndex)
{
    vec3 origin = getPosFromOffset(p,-t);
    vec3 target = getPosFromOffset(p,-t-.1);
    float roll = (origin.x-target.x)*5.;
    mat3 lookAt = calcLookAtMatrix(origin,target+vec3(0,0,.1),roll);    
    return sdButterfly(target*lookAt,colorIndex);
}

float GetDist(vec3 p,out int colorIndex) 
{      
    float off = p.z-t;
    
    vec3 q = vec3(
        sin(off*.407),
        cos(off*.407),
        0.
   )*2.;
    
    int butterfly1ColorIndex = 0;
    float butterfly1 = getButterflyFromPos(p-q,butterfly1ColorIndex);
    butterfly1ColorIndex = butterfly1ColorIndex==0?BUTTERFLY_1_COLORINDEX_1:BUTTERFLY_1_COLORINDEX_2;
    
    vec3 trail1pos = getPosFromOffset(p,off);    
    float trail1 = sdBox(trail1pos-q-vec3(0.,0.,MAX_DIST),vec3(.2,.025,MAX_DIST)); 
    if (trail1 < butterfly1) {
        butterfly1 = trail1;
        if (mod(p.z,1.) < .5) {
            butterfly1ColorIndex = BUTTERFLY_1_COLORINDEX_1;
        } else {
            butterfly1ColorIndex = BUTTERFLY_1_COLORINDEX_2;
        }
    }

    int butterfly2ColorIndex = 0;
    float butterfly2 = getButterflyFromPos(p+q,butterfly2ColorIndex);
    butterfly2ColorIndex = butterfly2ColorIndex==0?BUTTERFLY_2_COLORINDEX_1:BUTTERFLY_2_COLORINDEX_2;

    vec3 trail2pos = getPosFromOffset(p,off);       
    float trail2 = sdBox(trail2pos+q*1.-vec3(0.,0.,MAX_DIST),vec3(.2,.025,MAX_DIST));
    if (trail2 < butterfly2) {
        butterfly2 = trail2;
        if (mod(p.z,1.) < .5) {
            butterfly2ColorIndex = BUTTERFLY_2_COLORINDEX_1;
        } else {
            butterfly2ColorIndex = BUTTERFLY_2_COLORINDEX_2;
        }
    }
    
    if (butterfly1<butterfly2) {
        colorIndex = butterfly1ColorIndex;
        return butterfly1;
    } else { 
        colorIndex = butterfly2ColorIndex;
        return butterfly2;
    }
}

float GetDist(vec3 p) {    
    int dontCare;
    return GetDist(p,dontCare);
}

float RayMarch(vec3 ro,vec3 rd,out int colorIndex) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro+rd*dO;
        float dS = GetDist(p,colorIndex);
        dO+= dS*.6;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.001,0);
    
    vec3 n = d-vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv,vec3 p,vec3 l,float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0),f)),
        u = cross(f,r),
        c = p+f*z,
        i = c+uv.x*r+uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;    
    vec3 col = vec3(0);    
    vec3 co = vec3(4,2,-3)*2.;    
    co.xz *= Rot(-(time+34.5)*.1);    
    vec3 cd = GetRayDir(uv,co,vec3(2,1,0),1.);    
    cd *= STEP_FACTOR;
    
    int colorIndex;
    float d = RayMarch(co,cd,colorIndex);
    
    if(d<MAX_DIST) {
        if (BUTTERFLY_1_COLORINDEX_1==colorIndex) {
            col = BUTTERFLY_1_COLOR_1;
        } else if (BUTTERFLY_1_COLORINDEX_2==colorIndex) {
            col = BUTTERFLY_1_COLOR_2;
        } else if (BUTTERFLY_2_COLORINDEX_1==colorIndex) {
            col = BUTTERFLY_2_COLOR_1;
        } else if (BUTTERFLY_2_COLORINDEX_2==colorIndex) {
            col = BUTTERFLY_2_COLOR_2;
        }
        vec3 p = co+cd*d;
        vec3 n = GetNormal(p);
        
        float dif = dot(n,normalize(vec3(1,2,3)))*.5+.5;
        col *= dif;  
    }
    
    // Increase contrast for bright trippy colors
    col = clamp(col*1.5,0.,1.);
    
    // Fog
    col *= clamp(exp(-0.00008*d*d),0.02,1.);
    
    // Gamma correction
    col = pow(col,vec3(.4545));
    
    glFragColor = vec4(col,1.);
}
