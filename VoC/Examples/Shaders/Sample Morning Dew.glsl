#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/4dKfDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Morning Dew by Martijn Steinrucken aka BigWings - 2019
// Twitter: @The_ArtOfCode
// countfrolic@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

#define MAX_STEPS 200
#define MIN_DISTANCE 0.1
#define MAX_DISTANCE 50.
#define RAY_PRECISION 0.03

#define REFLECTIONS

const float halfpi = 1.570796326794896619;
const float pi = 3.141592653589793238;
const float twopi = 6.283185307179586;

#define S(a, b, t) smoothstep(a, b, t)
#define sat(x) clamp(x, 0., 1.)
#define PI 3.14159265
#define R3 1.732051

#define M1 1597334677U     //1719413*929
#define M2 3812015801U     //140473*2467*11  is also first 32bits of M1*M1

#define N21 N21dot

// from James_Harnett - Simplest Fastest 2d Hash 
// https://www.shadertoy.com/view/MdcfDj
float hash( uvec2 q ) {
    q *= uvec2(M1, M2); 
    
    uint n = (q.x ^ q.y) * M1;
    
    return float(n) * (1.0/float(0xffffffffU));
}

// Returns hexagonal coordinates. 
// XY = polar uv coords,  ZW = hex id 
vec4 HexCoordsPolar(vec2 uv) {
    vec2 s = vec2(1, R3);
    vec2 h = .5*s;

    vec2 gv = s*uv;
    
    vec2 a = mod(gv, s)-h;
    vec2 b = mod(gv+h, s)-h;
    
    vec2 ab = dot(a,a)<dot(b,b) ? a : b;
    vec2 st = vec2(atan(ab.x, ab.y), length(ab));
    vec2 id = gv-ab;
    
    return vec4(st, id);
}

// Returns hexagonal coordinates. 
// XY = polar uv coords,  ZW = hex id 
vec4 HexCoords(vec2 uv) {
    vec2 s = vec2(1, R3);
    vec2 h = .5*s;

    vec2 gv = s*uv;
    
    vec2 a = mod(gv, s)-h;
    vec2 b = mod(gv+h, s)-h;
    
    vec2 ab = dot(a,a)<dot(b,b) ? a : b;
    vec2 st = ab;//vec2(atan(ab.x, ab.y), length(ab));
    vec2 id = gv-ab;
    
    return vec4(st, id);
}

// returns the distance from a point to a rect (center-size)
float DistRect(vec4 r, vec2 p) { 
    vec2 d = max(abs(p - r.xy) - r.zw*.5, 0.);
    return dot(d, d);
}

float GetT(vec2 p, vec2 a, vec2 b) {
    vec2 ba = b-a;
    vec2 pa = p-a;
    
    float t = dot(ba, pa)/dot(ba, ba);
    
    return t;
}

vec2 ClosestPointSeg2D(vec2 p, vec2 a, vec2 b) {
    vec2 ba = b-a;
    vec2 pa = p-a;
    
    float t = dot(ba, pa)/dot(ba, ba);
    t = sat(t);
    
    return a + ba*t;
}

float DistSeg2d(vec2 uv, vec2 a, vec2 b) {
    return length(uv-ClosestPointSeg2D(uv, a, b));
}

float N(float p) {
    return fract(sin(p*6453.2)*3425.2);
}

vec3 N23(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
vec3 N23(float x, float y) {return N23(vec2(x, y));}

float N21sin(vec2 p) {
    p = p*132.3+vec2(345.45,2345.3);
    return fract(sin(p.x+p.y*1534.2)*7363.2);
}

float N21dot(vec2 p) {
    p = fract(p*vec2(345.45,2345.3));
    p += dot(p, p+123.345);
    return fract(p.x*p.y);
}

vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(p+n));
}

vec2 N12(float p) {
    float x = N(p);
    return vec2(x, N(p*100.*x));
}

float N2(vec2 p)
{    // Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float N2(float x, float y) { return N2(vec2(x, y)); }

float SmoothNoise(vec2 uv) {
    // noise function I came up with
    // ... doesn't look exactly the same as what i've seen elswhere
    // .. seems to work though :)
    vec2 id = floor(uv);
    vec2 m = fract(uv);
    m = 3.*m*m - 2.*m*m*m;
    
    float top = mix(N2(id.x, id.y), N2(id.x+1., id.y), m.x);
    float bot = mix(N2(id.x, id.y+1.), N2(id.x+1., id.y+1.), m.x);
    
    return mix(top, bot, m.y);
}

float LayerNoise(vec2 uv) {
    float c = SmoothNoise(uv*4.);
    c += SmoothNoise(uv*8.)*.5;
    c += SmoothNoise(uv*16.)*.25;
    c += SmoothNoise(uv*32.)*.125;
    c += SmoothNoise(uv*65.)*.0625;
    
    return c / 2.;
}

vec3 SmoothNoise3(vec2 uv) {
    // noise function I came up with
    // ... doesn't look exactly the same as what i've seen elswhere
    // .. seems to work though :)
    vec2 id = floor(uv);
    vec2 m = fract(uv);
    m = 3.*m*m - 2.*m*m*m;
    
    vec3 top = mix(N23(id.x, id.y), N23(id.x+1., id.y), m.x);
    vec3 bot = mix(N23(id.x, id.y+1.), N23(id.x+1., id.y+1.), m.x);
    
    return mix(top, bot, m.y);
}

vec3 LayerNoise3(vec2 uv) {
    vec3 c = SmoothNoise3(uv*4.);
    c += SmoothNoise3(uv*8.)*.5;
    c += SmoothNoise3(uv*16.)*.25;
    c += SmoothNoise3(uv*32.)*.125;
    c += SmoothNoise3(uv*65.)*.0625;
    
    return c / 2.;
}

vec2 Rot2d(vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    return vec2(p.x*s-p.y*c, p.x*c+p.y*s);
}

float smin( float a, float b, float k ) {
    float h = sat( 0.5+0.5*(b-a)/k );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k ) {
    float h = sat( 0.5+0.5*(b-a)/k );
    return mix( b, a, h ) + k*h*(1.0-h);
}

vec2 m; // mouse

float X2(float x) {return x*x;}

float N31(vec3 t) {return fract(sin((t.x+t.y*10.+ t.z*100.)*9e2));}
vec4 N14(float t) {return fract(sin(vec4(1., 3., 5., 7.)*9e2));}

float LN(float x) {return mix(N(floor(x)), N(floor(x+1.)), fract(x));}

struct ray {
    vec3 o;
    vec3 d;
};

struct de {
    // data type used to pass the various bits of information used to shade a de object
    float d;    // distance to the object
    float md;    // closest distance
    float m;     // material
    vec3 p;        // world space position
};
    
struct rc {
    // data type used to handle a repeated coordinate
    vec3 id;    // holds the floor'ed coordinate of each cell. Used to identify the cell.
    vec3 h;        // half of the size of the cell
    vec3 p;        // the repeated coordinate
};

ray GetRay(vec2 uv, vec3 p, vec3 lookAt, float zoom, vec3 up) {
    
    vec3 f = normalize(lookAt-p),
         r = normalize(cross(up, f)),
         u = cross(f, r),
         c = p+f*zoom,
         i = c+r*uv.x+u*uv.y;    // point in 3d space where cam ray intersects screen
    
    ray cr;
    
    cr.o = p;                        
    cr.d = normalize(i-p);        // ray dir is vector from cam pos to screen intersect 
    return cr;
}

float remap01(float a, float b, float t) { return (t-a)/(b-a); }
float remap(float a, float b, float c, float d, float t) { return sat((b-a)/(t-a)) * (d-c) +c; }

float DistLine(vec3 ro, vec3 rd, vec3 p) {
    return length(cross(p-ro, rd));
}

vec2 within(vec2 uv, vec4 rect) {
    return (uv-rect.xy)/rect.zw;
}

// DE functions from IQ
// https://www.shadertoy.com/view/Xds3zN

float sdSphere( vec3 p, vec3 pos, float s ) { return length(p-pos)-s; }

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdCylinder( vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCone( vec3 p, vec3 c ) {
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.*pi/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}

mat2 Rot(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float Bounce2(float t) {
    
    t *= 2.75+.3;
    t-=1.+.3;
    
    float a = 0.;
    float b = 1.-t*t;
    float c = -4.*(t-1.)*(t-1.5);
    float d = -4.*(t-1.5)*(t-1.75);
    
    float ab = smin(a, b, -.1);
    float cd = smin(c, d, -.1);
    
    float y = smin(ab, cd, -.1);
    
    return y;
}

float Wave(float d, float t) {
    float x = d-t*10.;
    
    float wave = sin(x)/(1.+x*x);
    float s = S(14., 0., d);
    return wave*s*s*1.5;
}

float V2(vec3 p, float t) {
    
   
    
   // p *= mix(1., .5, S(.8, .99, t));
    //p *= 1.-.5*t;
    
    float dc = length(p.xz);
    
    float m = mouse.x*resolution.xy.x/resolution.x;
   //t = m;
    t *= 2.;
    
    float eject = S(0., .1, t);
    float eject2 = eject*S(.3, .1, t);
    float dropSize = mix(1., .5, eject);
    
    float t1 = t;
    float t2 = t-.75;
    float t3 = t-.875;
    
    float t4 = t-.4;
    
    float w1 = Wave(dc, t1)* S(0., .05, t1);
    float w2 = Wave(dc, t2)* S(0., .05, t2);
    float w3 = Wave(dc, t3)* S(0., .05, t3);
    
    float w4 = Wave(dc, t4)* S(0., .05, t4);
    
    float wave = w1 + .5*w2 + .25*w3 + .25*w4;
    
    float cw = Wave(0., t1) + Wave(0., t2)*.5 + Wave(0., t3)*.4;
    
    float b = Bounce2(t*1.);
    float y = b*6.+dropSize+cw-.1;
    y -= .6*S(1., .85, t);
    y += (1.-eject)*.5;
    y -= eject2;
    
    
    float x = sin(t*30.+p.z*9.)*.05*b;
    float z = sin(t*33.+p.x*7.)*.05*b;
    
    float drop = length(p-vec3(x, y, z))-dropSize;
    
    float surf = abs(p.y);
    
    surf -= wave;
    
    surf *= .75;
    float d = smin(surf, drop, eject2*2.);
    
    x = z = 0.;
   // t = (t-1.);
    
    y = -(t-.2)*(t-.5)*100.-.5;
    drop = length(p-vec3(x, y, z))-.5;
    d = smin(d, drop, max(1.-y, .1));
    
    y = -(t-.15)*(t-.55)*100.-.5;
    d = smin(d, length(p-vec3(x, y, z))-.25, .8);
    
    y = -(t-.13)*(t-.56)*100.-.25;
    d = smin(d, length(p-vec3(x, y, z))-.15, .8);
    
    return d;
}

float V3(vec3 p, float t) {
    vec2 size = vec2(25.);
    vec2 id = floor(p.xz/size);
    p.xz = mod(p.xz, vec2(size))-size*.5;
    
    float n = N21(id);
    
    t = fract(t*.2+n);
    
   return V2(p, t);
}

float map( vec3 p ) {
    
    float t = time;
   // t += sin(t*.3);
    //p.xz += t*2.;
    
    float d = V3(p, t);
    
    float s = sin(PI*.25);
    float c = cos(PI*.25);
    mat2 rot = mat2(c, -s, s, c);
    
   // p.xz *= 2.*rot;
    p.xz += vec2(12.34, 34.45);
    d = smin(d, V3(p, t), .1);
    
    return d;
}

float calcAO( in vec3 pos, in vec3 nor ){
    float dd, hr, sca = 1., totao = 0.;
    vec3 aopos; 
    for( int aoi=0; aoi<5; aoi++ ) {
        hr = .01 + .05*float(aoi);
        aopos =  nor * hr + pos;
        totao += -(map( aopos )-hr)*sca;
        sca *= .5;
    }
    return clamp(1. - 4.*totao, 0., 1.);
}

de castRay( ray r, float precis ) {
    
    float t = time;
    float dS;
    
    de o;
    o.d = MIN_DISTANCE;
    o.md = MAX_DISTANCE;
    o.m = -1.0;
    
    float d;
    for( int i=0; i<MAX_STEPS; i++ ) {
        o.p =  r.o+r.d*o.d;
 
        d = map(o.p);
        
        o.md = min(o.md, d);
        if( d<precis || o.d>MAX_DISTANCE ) break;
        
        o.d += d;
    }
    
    if(d<precis) o.m = 1.;
    
    return o;
}

vec3 calcNormal( de o )
{
    vec3 eps = vec3( 0.01, 0.0, 0.0 );
    vec3 nor = vec3(
        map(o.p+eps.xyy) - map(o.p-eps.xyy),
        map(o.p+eps.yxy) - map(o.p-eps.yxy),
        map(o.p+eps.yyx) - map(o.p-eps.yyx) );
    return normalize(nor);
}

vec3 Bg(vec3 rd) {
    float y = mouse.y*resolution.xy.y/resolution.y;
    y = sin(time*.1)*.15+.7;
    return vec3(.5)*(rd.y+1.)*y;
}

vec3 render( vec2 uv, ray cam ) {
    
    float t = time;
    
    vec3 col = vec3(0.);
    de o = castRay(cam, RAY_PRECISION);
    
    vec3 n = calcNormal(o);
    
    float d = length(o.p-cam.o);
    float fresnel = 1.-sat( dot(-cam.d, n) );
    
    if(o.m==1.) {
        float ao = calcAO(o.p, n);
        
        float dif = .1+sat(dot(n, vec3(.577)));
        dif = mix(ao, dif, .5);
        
        
        col = vec3(dif);
        
        
        #ifdef REFLECTIONS
        ray r;
        r.d = reflect(cam.d, n);
        r.o = o.p+r.d*.1;
        
        de ro = castRay(r, .03);
        float ref = 0.;
        if(ro.m==1.) {
            vec3 rn = calcNormal(ro);
            
            float rao = calcAO(ro.p, rn);
        
            float rdif = .1+sat(dot(rn, vec3(.577)));
            ref = mix(rao, rdif, .5)*.3;
            
        }
        
        col += ref*fresnel;
        #endif
    }
    vec3 bg = Bg(cam.d);
    col = mix(bg, col, (1.-fresnel)*S(50., 0., d));
   // col = bg;
    return col;
}

vec3 FlightPath(float t) {
    //t *= .3;
    float a = sin(t)*.5+.5;
    float b = a*a;
    float x = -sin(t*.25)*30.;
    float y = sin(t*.225)+1.2 + sin(.2456*t)+1.5;
   // y = mix(2., 12., b*b);
    return vec3(x, y, t*10.);
}

void main(void)
{
    vec4 o = glFragColor;
    vec2 uv = gl_FragCoord.xy;

    float t = time;
    
    uv = (2.*uv - (o.xy=resolution.xy) ) / o.y ;      // -1 <> 1
       m = mouse*resolution.xy.xy/resolution.xy;                    // 0 <> 1
    
    float turn =m.x*6.283;
    float s = sin(turn);
    float c = cos(turn);
    mat3 rotX = mat3(      c,  0., s,
                             0., 1., 0.,
                             s,  0., -c);
    
    m.y -= .5;
    s = sin(m.y*PI*.5);
    c = cos(m.y);
    vec3 pos = vec3(0., (1.-s)*6., -6.*c)*rotX;
       vec3 lookAt = vec3(0., 1.5, 0.);
    
    float y = sin(t)*2.+1.;
    pos = FlightPath(t);
    lookAt = FlightPath(t+1.1)+vec3(0., -2.5, .1);
    
    float a = sin(t*.25)*.25;
    vec3 up = vec3(sin(a), cos(a), 0.);
    ray r = GetRay(uv, pos, lookAt, 1., up);

    vec3 col = render(uv, r);
    
    
    if(pos.y>0.)
    col = 1.-col;
    //col *= 1.5;
    
    col *= 1. - dot(uv, uv)*.125;
    col *= 1.5;
    
    col *= col;
    
     col *= vec3(1., .9+sin(t*.36)*.1, .9+sin(t*.3)*.1);
   
    o = vec4(col, 1.);

    glFragColor = o;
}
