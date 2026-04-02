#version 420

// original https://www.shadertoy.com/view/3lVfRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "RayMarching starting point" by BigWIngs. https://shadertoy.com/view/WtGXDD
#define MAX_STEPS 200
#define MAX_DIST 100.
#define SURF_DIST .001
#define S smoothstep
#define T time*.3
#define TAU 6.283185
 
// a flat band of 1 unit wide, wound around an infinite cylinder of radius r
// with UV parameters
vec3 wrappedCylinder(vec3 p, float r) 
{
    p.y-=-.5; // center the starting point at y=zero
    float tpr = atan(p.z, p.x);
    float tp = tpr/TAU;
    float turn = p.y-tp;      // counting the turns
    float count=floor(turn);
    float delta=fract(turn);
    float ts=tp+count;
    float u=ts*r*TAU;
    float v=delta-.5; // from -.5 to .5
    // fix orientation regarding the slope
     float slope = 1.0/(TAU*r);
     u+=v*slope/sqrt(1.0+slope*slope); // sin(atan(x)) = x/sqrt(x2+1)
     // distance calculation
    float d = length(p.xz) - r;
    return vec3(d,u,v);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec4 ribbon(vec3 p, float r, float spacing, vec2 thickness)
{
    float scale=spacing+1.0;
    vec3 duv = scale*wrappedCylinder(p/scale,r/scale); // I wonder if distances may be preserved
    float w=duv.x;
    vec2 uv=duv.yz;
    vec2 q=duv.xz;
    float d=sdBox(q,thickness*.5);
    return vec4(d,uv,w);
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float GetDist(vec3 p) {      
    vec4 duvw =  ribbon(p,1.9854+sin(T),0.3643,vec2(.2));
    vec3 p2=duvw.zyw;
    p2.y+=time;
    vec4 duvw2 = ribbon(p2,.3,0.0,vec2(.1,.5));
    float d=min(duvw.x+.05,duvw2.x);
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p), // forward vector
        r = normalize(cross(f,vec3(0,1,0) )),   // right vector
        u = cross(r,f),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

// Inigo
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<24; i++ )
    {
        float h = GetDist( ro + rd*t );
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://www.shadertoy.com/view/Xds3zN
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0); // up vector
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = vec2(0);
    
    vec3 ro = vec3(0, 1, 5);
    vec3 ta = vec3(0,0,0);
    //if ( mouse*resolution.xy.x > 0.0 ) {
    //    m=2.0*mouse*resolution.xy.xy/resolution.xy-1.0;
    //    ro.yz *= Rot(-m.y*3.14);
    //    ro.xz *= Rot(-m.x*6.2831);
    //}
    vec3 rd = GetRayDir(uv, ro, ta, 1.);
    float d = RayMarch(ro, rd);
    
    vec3 col = vec3(0); 
    if(d<MAX_DIST) {
        col = vec3(1.,1.,1.0)*.3;
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        // Blackle https://www.shadertoy.com/view/ttGfz1
        float dif=pow(length(sin(n*3.)*.5+.5)/sqrt(3.), 4.);
        vec3  sun_lig = normalize( vec3(0.2, 0.35, 0.5) );
        float sun_sha = calcSoftshadow( p+0.01*n, sun_lig, 0.1, 1.1 );
        col *= dif*3.*(sun_sha+.1);  
    }
    col = sqrt(col);    // gamma correction
    glFragColor = vec4(col,1.0);
}
