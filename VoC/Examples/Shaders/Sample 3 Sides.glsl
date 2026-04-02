#version 420

// original https://www.shadertoy.com/view/fldGR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on https://www.shadertoy.com/view/sllGDN
// by Martijn Steinrucken aka The Art of Code/BigWings - 2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Performance settings
// Enabling AA is more expensive but looks quite a lot better
#define USE_AA 0
// Continue further raycast after refraction?
#define MAX_RAYS_PER_PRIMARY 3.

#define MAX_STEPS 128
#define MAX_DIST 100.
#define SURF_DIST .001

#define S smoothstep
#define T time

const int MAT_BASE=1;
const int MAT_BARS=2;
const int MAT_BALL=3;
const int MAT_LINE=4;

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

// from https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdBox(vec2 p, vec2 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, p.y), 0.);
}

float sdLineSeg(vec3 p, vec3 a, vec3 b) {
    vec3 ap=p-a, ab=b-a;
    float t = clamp(dot(ap, ab)/dot(ab, ab), 0., 1.);
    vec3 c = a + ab*t;
    return length(p-c);
}

vec2 sdBall(vec3 p, float a) {
    
    p.y-=1.01;
    p.xy *= Rot(a);
    p.y+=1.01;
    
    float ball = length(p)-.15;
    float ring = length(vec2(length(p.xy-vec2(0, .15))-.03, p.z))-.01;
    ball = min(ball, ring);
    
    p.z = abs(p.z);
    float line = sdLineSeg(p, vec3(0,.15,0), vec3(0, 1.01, .4))-.005;
    
    float d = min(ball, line);
    
    return vec2(d, d==ball ? MAT_BALL : MAT_LINE);
}

float udIsoTriangle( vec3 p, float r )
{
  const float cos30 = 0.86602540378;
  float h = r;
  vec3 a = vec3(-h, -h*cos30, 0.);
  vec3 b = vec3(+h, -h*cos30, 0.);
  vec3 c = vec3( 0,  h*cos30, 0.);
  vec3 ba = b - a; vec3 pa = p - a;
  vec3 cb = c - b; vec3 pb = p - b;
  vec3 ac = a - c; vec3 pc = p - c;
  vec3 nor = cross( ba, ac );

  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float sdPrism( in vec3 p, in float r, in float h )
{
    float d = udIsoTriangle(vec3(p.xy, 0.), r);
    vec2 w = vec2( d, abs(p.z) - h );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

float nGon(in int n, in vec2 p, in float r) {
    // these 2 lines can be precomputed
    float an = 6.2831853 / float(n);
    float he = r * tan(0.5 * an);

    // rotate to first sector
    p = -p.yx; // if you want the corner to be up
    float bn = an * floor((atan(p.y, p.x) + 0.5 * an) / an);
    vec2 cs = vec2(cos(bn), sin(bn));
    p = mat2(cs.x, -cs.y, cs.y, cs.x) * p;

    // side of polygon
    return length(p - vec2(r, clamp(p.y, -he, he))) * sign(p.x-r);
}

// for the distance result of any 2D SDF, returns a 3D prism for the 3rd axis position value v
float toPrism(in float d2d, in float v, in float size) {
    vec2 d = vec2(d2d, abs(v) - 0.5 * size);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float nPrism(in int n, in vec3 p, in float r, in float depth) {
    float d = nGon(n, p.xy, r);
    return toPrism(d, p.z, depth);
}

float sdTriPrism( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

vec2 Min(vec2 a, vec2 b) {
    return a.x<b.x ? a : b;
}

float noise(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float fbm( vec2 x, float H )
{    
    float G = exp2(-H);
    float skip = 0.;
    float f = pow(2., skip);
    float a = pow(G, skip);
    float t = 0.0;
    for( int i=0; i<10; i++ )
    {
        t += a*noise(f*x);
        f *= 2.0;
        a *= G;
    }
    return t;
}

vec2 GetDist(vec3 p) {
    float d = MAX_DIST;
    int mat = MAT_BALL;
    
    // p.xz *= Rot(.005 * sqrt(dot(p.xz, p.xz)));
    
    vec3 prism_origin = vec3(0.,.8,0.);
    vec3 prism_query = p - prism_origin;
    prism_query.yz *= Rot(3.14159 * .15);
    prism_query.xy *= Rot(time);
        
    float c = 7.;
    prism_query = mod(prism_query+0.5*c,c)-0.5*c;

    // d = nPrism(3, prism_query, 0.3, 2.) - 0.02;
    // d = sdBox(prism_query, vec3(0.4)) - 0.02;
    d = sdPrism(prism_query, .5, 1.) - 0.02;
    
    return vec2(d, mat);
}

vec2 RayMarch(vec3 ro, vec3 rd, float side) {
    float dO=0.;
    vec2 dSMat = vec2(0);
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        dSMat = GetDist(p)*side;
   
        dO += dSMat.x;
        if(dO>MAX_DIST || abs(dSMat.x)<SURF_DIST) break;
    }
    
    return vec2(dO, dSMat.y);
    //return vec2(MAX_DIST, 0.);
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

vec3 EnvCol(vec3 rd) {
  vec3 ground_col = vec3(.2,.25,.3);
  vec3 sky_col = vec3(.6, .9, .9);
  float t = smoothstep(.4, .6, rd.y * .5 + .5);
  vec3 sky = t * sky_col + (1.-t) * ground_col;
  float theta = atan(rd.z, rd.x);
  float phi = atan(rd.y, rd.x);
  float rzx = dot(rd.xz, rd.xz);
  float sky_top = 1. * sin(theta * 12.) + .2;
  //float sky_top = - .5*fbm(.001 * vec2(theta, phi), .5);
  float sky_bottom = .6 * sin(rzx * 3.14159); // + .05 * cos(theta * 357.8746) * sin(rzx * 3.14159 * 454.8465);
  float t2 = smoothstep(-.2, 0., rd.y);
  return sky + (t2 * sky_top + (1.-t2) * sky_bottom);
}

vec4 Render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last) {
    vec3 col = EnvCol(rd);
    vec2 dMat = RayMarch(ro, rd, 1.);
    float d = dMat.x;
    
    ref *= 0.;
    
    float alpha = 0.;
    const float IOR = 1.35; // index of refraction
    
    if (d < MAX_DIST) {
        vec3 p = ro + rd * d; // 3d hit position
        vec3 n = GetNormal(p); // normal of surface... orientation
        vec3 r = reflect(rd, n);
        // Colour of reflection, going to environment
        vec3 refOutside = EnvCol(r);
        
        // Ray refracted internally
        vec3 rdIn = refract(rd, n, 1./IOR); // ray dir when entering

        vec3 pEnter = p - n*SURF_DIST*3.;
        float dIn = RayMarch(pEnter, rdIn, -1.).x; // inside the object

        vec3 pExit = pEnter + rdIn * dIn; // 3d position of exit
        vec3 nExit = -GetNormal(pExit);

        vec3 rdOut = refract(rdIn, nExit, IOR);
        if (dot(rdOut, rdOut) == 0.) {
          rdOut = reflect(rdIn, nExit);
        }

        // Next iteration's ray
        ro = pExit - nExit*SURF_DIST*3.;
        rd = rdOut;
        alpha = 1.;
        
        float fresnel = pow(1.+dot(rd, n), 5.);

        // The rest of the mixing happens in the RenderAll loop
        col = vec3(0);
        ref = vec3(.8);
        if (last) {
          // We won't spawn a further ray, but get the colour of the refracted ray going to environment
          const float dens = .1;
          float optDist = exp(-dIn*dens);
          vec3 reflTex = EnvCol(rdOut) * optDist;
          col += reflTex*ref;
        }
        col = mix(col, refOutside, fresnel);
    }
    return vec4(col, alpha);
}

vec3 RenderAll() {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    vec3 ro = vec3(0, 3, -3);

    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(time * .3);
    ro.xz *= Rot(-m.x*6.2831);

    vec3 rd = GetRayDir(uv, ro, vec3(0,0.75,0), 2.);
    vec3 col = vec3(0.);
    vec3 ref, fil=vec3(1);
   
    for(float i=0.; i<MAX_RAYS_PER_PRIMARY; i++) {
        vec4 pass = Render(ro, rd, ref, i==MAX_RAYS_PER_PRIMARY-1.);
        col += pass.rgb*fil;
        fil*=ref;
    }
    
    return col;
}

void main(void)
{
    vec3 col = RenderAll();
    
    // Anti-aliasing
    #if USE_AA
    col +=
        RenderAll(gl_FragCoord.xy+vec2(.5,.0))+
        RenderAll(gl_FragCoord.xy+vec2(.0,.5))+
        RenderAll(gl_FragCoord.xy+vec2(.5,.5));
    col /= 4.;
    #endif
    
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
