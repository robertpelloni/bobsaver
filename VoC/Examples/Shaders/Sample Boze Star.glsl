#version 420

// original https://neort.io/art/c0glnes3p9f30ks5bfig

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// ------------------------------------------------------------------------------------
// Original Character By MikkaBouzu : https://twitter.com/mikkabouzu777
// ------------------------------------------------------------------------------------

#define saturate(x) clamp(x, 0.0, 1.0)
#define MAX_MARCH 200
#define MAX_DIST 100.

const float EPS = 1e-3;
const float EPS_N = 1e-4;
const float OFFSET = EPS * 10.0;

#define M_PI 3.1415926
#define M_PI2 6.2831852
#define M_PI03 1.04719
#define M_PI06 2.09439

#define RAD90 (M_PI * 0.5)

struct surface {
    float dist;
    vec4 albedo;
    int count;
    bool isHit;
};

// Surface Data Define
#define SURF_NOHIT(d)   (surface(d, vec4(0),              0, false))
#define SURF_BLACK(d)     (surface(d, vec4(0,0,0,1),       0, true))
#define SURF_FACE(d)     (surface(d, vec4(1,0.7,0.6,1),     0, true))
#define SURF_MOUSE(d)     (surface(d, vec4(1,0,0.1,1),       0, true))
#define SURF_CHEEP(d)     (surface(d, vec4(1,0.3,0.4,1),     0, true))

vec3 sinebow(float h) {
    vec3 r = sin((.5-h)*M_PI + vec3(0,M_PI03,M_PI06));
    return r*r;
}

float easeInOutCubic(float x) {
    return x < 0.5 ? 4. * x * x * x : 1. - pow(-2. * x + 2., 3.) / 2.;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Basic Distance function
/////////////////////////////////////////////////////////////////////////////////////////////////
float sdRoundBox(vec3 p, vec3 size, float r)
{
    return length(max(abs(p) - size * 0.5, 0.0)) - r;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdEllipsoid( vec3 p, vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

vec3 rotate(vec3 p, float angle, vec3 axis)
{
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

mat2 rotate(in float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

// https://www.shadertoy.com/view/Mlf3Wj
vec2 foldRotate(in vec2 p, in float s) {
    float a = M_PI / s - atan(p.x, p.y);
    float n = M_PI2 / s;
    a = floor(a / n) * n;
    p *= rotate(a);
    return p;
}

// Union, Subtraction, SmoothUnion (distance, Material) 
surface opU(surface d1, surface d2)
{
    if(d1.dist < d2.dist){
        return d1;
    } else {
        return d2;
    }
}

float opU( float d1, float d2 ) {  return min(d1,d2); }

surface opS( surface d1, surface d2 )
{
    if(-d1.dist > d2.dist){
        d1.dist = -d1.dist;
        return d1;
    } else {
        return d2;
    }
}

surface opSU( surface d1, surface d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2.dist - d1.dist)/k, 0.0, 1.0 );
    float d = mix( d2.dist, d1.dist, h ) - k*h*(1.0-h);
    vec4 albedo = mix( d2.albedo, d1.albedo, h );
    return surface(d, albedo, d1.count, true);
}

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Mikka Boze Distance Function
/////////////////////////////////////////////////////////////////////////////////////////////////
float sdEar(vec3 p)
{
    p = rotate(p, RAD90+0.25, vec3(0,0,1));    
    return sdCappedTorus(p + vec3(0.05, 0.175, 0), vec2(sin(0.7),cos(0.7)), 0.03, 0.01);
}

#define EYE_SPACE 0.04

vec3 opBendXY(vec3 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xy,p.z);
}

vec3 opBendXZ(vec3 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec2 xz = m*p.xz;
    return vec3(xz.x, p.y, xz.y);
}

float sdMouse(vec3 p, float ms)
{
    vec3 q = opBendXY(p, 2.0);
    ms += 0.00001;
    return sdEllipsoid(q - vec3(0,0,0.2), vec3(0.035, 0.01 * ms,0.05 * ms));
}

float sdCheep(vec3 p)
{    
    const float x = 0.05;
    const float z = -0.175;
    const float r = 0.0045;
    const float rb1 = 100.;
    
    p = rotate(p, M_PI * -0.6 * (p.x - x), vec3(-0.2,0.8,0));
    
    float d = sdCapsule(opBendXY(p + vec3(x, -0.01, z), rb1), vec3(-0.005,0.0,0.0), vec3(0.005, 0., 0.001), r);
    float d1 = sdCapsule(opBendXY(p + vec3(x+0.01, -0.01, z), 200.0), vec3(-0.0026,0.0,0), vec3(0.0026, 0., 0), r);
    float d2 = sdCapsule(opBendXY(p + vec3(x+0.019, -0.015, z), -rb1), vec3(-0.01,0.0,-0.01), vec3(0.0045, 0., 0.0), r);
    
    return opU(opU(d, d1), d2);
}

float sdEyeBrow(vec3 p)
{
    const float x = 0.05;
    p = opBendXZ(p + vec3(0.02,0,-0.02), -6.5);
    return sdRoundBox(p + vec3(0.005, -0.14,-0.11), vec3(0.003,0.0025,0.05), 0.001);
}

surface sdBoze(vec3 p, vec3 sc, float ms)
{    
    surface result = SURF_NOHIT(1e5);
    
    float minsc = min(sc.x, min(sc.y, sc.z));
    p /= sc;
    
    // head
    float d = sdCapsule(p, vec3(0,0.05,0), vec3(0, 0.11, 0), 0.125);
    
    float d1 = sdRoundedCylinder(p + vec3(0,0.025,0), 0.095, 0.05, 0.0);
    
    d = smin(d, d1, 0.1);
    
    vec3 mxp = vec3(-abs(p.x), p.yz);
    
    // ear
    float d2 = sdEar(mxp);
    d = opU(d, d2);

    surface head = SURF_FACE(d);
    head.albedo = vec4(sinebow(time) + 0.5,1);
    
    // eye
    float d4 = sdCapsule(mxp, vec3(-EYE_SPACE, 0.06, 0.13), vec3(-EYE_SPACE, 0.08, 0.125), 0.0175);
    surface eye = SURF_BLACK(d4);
    
    // mouse
    float d6 = sdMouse(p, ms);
    surface mouse = SURF_MOUSE(d6);
    
    // cheep
    float d7 = sdCheep(mxp);
    surface cheep = SURF_CHEEP(d7);
    
    // eyebrows
    float d9 = sdEyeBrow(mxp);
    eye.dist = opU(eye.dist, d9);
    
    // integration
    mouse = opU(eye, mouse);
    result = opS(mouse, head);
    result = opU(cheep, result);
    
    result.dist *= minsc;
    
    return result;
}
/////////////////////////////////////////////////////////////////////////////////////////////////
// End of Mikka Boze
/////////////////////////////////////////////////////////////////////////////////////////////////

surface map(vec3 p)
{
    surface result = SURF_NOHIT(1e5);
    
    float ms = abs(sin(time * 2.5) * 5.);

    p.y -= abs(sin(time*M_PI))*0.1;
    
    float r = easeInOutCubic(fract(time*1.0))*M_PI2;
    p = rotate(p, r, vec3(0,1,0));
    
    p.xy = foldRotate(p.xy, 5.);

    // boze
    surface boze = sdBoze(p, vec3(0.5, 1. + sin(p.y * 20. + time * 5.)*0.05, 0.25), ms);
    
    result = opU(result, boze);
    
    return result;
}

vec3 norm(in vec3 position) {
    // https://www.shadertoy.com/view/XltyRf
    vec4 n = vec4(0);
    for (int i = 0 ; i < 4 ; i++) {
        vec4 s = vec4(position, 0);
        s[i] += 0.001;
        n[i] = map(s.xyz).dist;
    }
    return normalize(n.xyz-n.w);
    
}

surface traceRay(in vec3 origin, in vec3 direction, float dist, out vec3 pos) {
    float t = 0.0;
    
    pos = origin;

    int count = 0;
    surface hit;
    float d;
    
    for (int i = 0; i < MAX_MARCH; i++) {
        hit = map(pos);
        d = hit.dist;
        
        if (d <= EPS || d >= MAX_DIST) {
            break;
        }

        t += d;
        pos = origin + direction * t;
        count++;        
    }

    hit.dist = t;
    hit.count = count;

    pos = origin + direction * t;
        
    if(hit.isHit)
    {
        // Lighting
        vec3 normal = norm(pos);

        //vec3 lightDir = normalize(vec3(cos(time), 1, sin(time)));
        vec3 lightDir = normalize(vec3(0,0.5,1));
        vec3 lightColor = vec3(1.5);
        
        float NoL = saturate(dot(normal, lightDir));
        
        vec3 ambientColor = vec3(0.5);
        
        hit.albedo.rgb *= NoL * lightColor +  ambientColor;
    }
    
    if(d <= EPS){
        hit.isHit = true;
        return hit;
    }else{
        
        hit.isHit = false;
        return hit;
    }
}
    
vec3 render(vec3 p, vec3 ray, vec2 uv)
{
    vec3 pos;
    surface mat = traceRay(p, ray, 0., pos);
    
    vec3 col = vec3(0,0,0);
    vec3 sky = vec3(0.);
    
    col = mat.isHit ? mat.albedo.rgb : sky;
    
    return col;
    
}

mat3 camera(vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 ro = vec3(0, 0.05, 0.5);
    vec3 ta = vec3(0, 0.05, 0);
    
    mat3 c = camera(ro, ta, 0.0);
    vec3 ray = c * normalize(vec3(p, 1.5));
    vec3 col = render(ro, ray, gl_FragCoord.xy);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
