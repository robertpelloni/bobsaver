#version 420

// original https://www.shadertoy.com/view/MlcGRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// --------------------------------------------------------
// OPTIONS
// --------------------------------------------------------

//#define DEBUG

#define PI 3.14159265359
#define PHI (1.618033988749895)

float t;

#define saturate(x) clamp(x, 0., 1.)

// --------------------------------------------------------
// HG_SDF
// https://www.shadertoy.com/view/Xs3GRB
// --------------------------------------------------------

#define GDFVector0 vec3(1, 0, 0)
#define GDFVector1 vec3(0, 1, 0)
#define GDFVector2 vec3(0, 0, 1)

#define GDFVector3 normalize(vec3(1, 1, 1 ))
#define GDFVector3b normalize(vec3(-1, -1, -1 ))
#define GDFVector4 normalize(vec3(-1, 1, 1))
#define GDFVector4b normalize(vec3(-1, -1, 1))
#define GDFVector5 normalize(vec3(1, -1, 1))
#define GDFVector5b normalize(vec3(1, -1, -1))
#define GDFVector6 normalize(vec3(1, 1, -1))
#define GDFVector6b normalize(vec3(-1, 1, -1))

#define GDFVector7 normalize(vec3(0, 1, PHI+1.))
#define GDFVector7b normalize(vec3(0, 1, -PHI-1.))
#define GDFVector8 normalize(vec3(0, -1, PHI+1.))
#define GDFVector8b normalize(vec3(0, -1, -PHI-1.))
#define GDFVector9 normalize(vec3(PHI+1., 0, 1))
#define GDFVector9b normalize(vec3(PHI+1., 0, -1))
#define GDFVector10 normalize(vec3(-PHI-1., 0, 1))
#define GDFVector10b normalize(vec3(-PHI-1., 0, -1))
#define GDFVector11 normalize(vec3(1, PHI+1., 0))
#define GDFVector11b normalize(vec3(1, -PHI-1., 0))
#define GDFVector12 normalize(vec3(-1, PHI+1., 0))
#define GDFVector12b normalize(vec3(-1, -PHI-1., 0))

#define GDFVector13 normalize(vec3(0, PHI, 1))
#define GDFVector13b normalize(vec3(0, PHI, -1))
#define GDFVector14 normalize(vec3(0, -PHI, 1))
#define GDFVector14b normalize(vec3(0, -PHI, -1))
#define GDFVector15 normalize(vec3(1, 0, PHI))
#define GDFVector15b normalize(vec3(1, 0, -PHI))
#define GDFVector16 normalize(vec3(-1, 0, PHI))
#define GDFVector16b normalize(vec3(-1, 0, -PHI))
#define GDFVector17 normalize(vec3(PHI, 1, 0))
#define GDFVector17b normalize(vec3(PHI, -1, 0))
#define GDFVector18 normalize(vec3(-PHI, 1, 0))
#define GDFVector18b normalize(vec3(-PHI, -1, 0))

#define fGDFBegin float d = 0.;

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
#define fGDFExp(v) d += pow(abs(dot(p, v)), e);

// Version with without exponent, creates objects with sharp edges and flat faces
#define fGDF(v) d = max(d, abs(dot(p, v)));

#define fGDFExpEnd return pow(d, 1./e) - r;
#define fGDFEnd return d - r;

// Primitives follow:

float fDodecahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector13) fGDF(GDFVector14) fGDF(GDFVector15) fGDF(GDFVector16)
    fGDF(GDFVector17) fGDF(GDFVector18)
    fGDFEnd
}

float fIcosahedron(vec3 p, float r) {
    fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12)
    fGDFEnd
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
    return dot(p, n) + distanceFromOrigin;
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Reflect space at a plane
float pReflect(inout vec3 p, vec3 planeNormal, float offset) {
    float t = dot(p, planeNormal)+offset;
    if (t < 0.) {
        p = p - (2.*t)*planeNormal;
    }
    return sign(t);
}

// --------------------------------------------------------
// http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
// --------------------------------------------------------

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
    );
}

// --------------------------------------------------------
// knighty
// https://www.shadertoy.com/view/MsKGzw
// --------------------------------------------------------

int Type=5;
vec3 nc;
vec3 pbc;
void initIcosahedron() {//setup folding planes and vertex
    float cospin=cos(PI/float(Type)), scospin=sqrt(0.75-cospin*cospin);
    nc=vec3(-0.5,-cospin,scospin);//3rd folding plane. The two others are xz and yz planes
    pbc=vec3(scospin,0.,0.5);//No normalization in order to have 'barycentric' coordinates work evenly
    pbc=normalize(pbc);
}

void pModIcosahedron(inout vec3 p) {
    p = abs(p);
    pReflect(p, nc, 0.);
    p.xy = abs(p.xy);
    pReflect(p, nc, 0.);
    p.xy = abs(p.xy);
    pReflect(p, nc, 0.);
}

// --------------------------------------------------------
// IQ
// https://www.shadertoy.com/view/ll2GD3
// --------------------------------------------------------

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 spectrum(float n) {
    return pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
}

// --------------------------------------------------------
// MAIN
// --------------------------------------------------------

vec3 vMin(vec3 p, vec3 a, vec3 b, vec3 c, vec3 d) {
    float la = length(p - a);
    float lb = length(p - b);
    float lc = length(p - c);
    float ld = length(p - d);
    if (la < lb) {
        if (la < lc) {
            if (la < ld) {
                return a;
            } else {
                return d;
            }
        } else {
            if (lc < ld) {
                return c;
            } else {
                return d;
            }
        }
    } else {
        if (lb < lc) {
            if (lb < ld) {
                return b;
            } else {
                return d;
            }
        } else {
            if (lc < ld) {
                return c;
            } else {
                return d;
            }
        }
    }
}

// Nearest dodecahedron vertex
vec3 dodecahedronVertex(vec3 p) {
    vec3 v = vec3(0);
    if (p.z > 0.) {
        if (p.x > 0.) {
            if (p.y > 0.) {
                return vMin(p, GDFVector3, GDFVector7, GDFVector9, GDFVector11);
            } else {
                return vMin(p, GDFVector5, GDFVector8, GDFVector9, GDFVector11b);
            }
        } else {
            if (p.y > 0.) {
                return vMin(p, GDFVector4, GDFVector7, GDFVector10, GDFVector12);
            } else {
                return vMin(p, GDFVector4b, GDFVector8, GDFVector10, GDFVector12b);
            }
        }
    } else {
        if (p.x > 0.) {
            if (p.y > 0.) {
                return vMin(p, GDFVector6, GDFVector7b, GDFVector9b, GDFVector11);
            } else {
                return vMin(p, GDFVector5b, GDFVector8b, GDFVector9b, GDFVector11b);
            }
        } else {
            if (p.y > 0.) {
                return vMin(p, GDFVector6b, GDFVector7b, GDFVector10b, GDFVector12);
            } else {
                return vMin(p, GDFVector3b, GDFVector8b, GDFVector10b, GDFVector12b);
            }
        }
    }
}

// Nearest vertex and distance.
// Distance is roughly to the boundry between the nearest and next
// nearest dodecahedron vertices, ensuring there is always a smooth
// join at the edges, and normalised from 0 to 1
vec4 dodecahedronAxisDistance(vec3 p) {
    vec3 iv = dodecahedronVertex(p);
    vec3 originalIv = iv;

    vec3 pn = normalize(p);
    pModIcosahedron(pn);
    pModIcosahedron(iv);

    float boundryDist = dot(pn, vec3(0, 1, 0));
    float boundryMax = dot(iv, vec3(0, 1, 0));
    boundryDist /= boundryMax;

    float roundDist = length(iv - pn);
    float roundMax = length(iv - vec3(0, 0, 1));
    roundDist /= roundMax;
    roundDist = -roundDist + 1.;
    
    float blend = 1. - boundryDist;
    blend = pow(blend, 6.);
    
    float dist = mix(roundDist, boundryDist, blend);
    dist = max(dist, 0.);
    
    return vec4(originalIv, dist);
}

// Twists p around the nearest icosahedron vertex
void pTwistDodecahedron(inout vec3 p, float amount) {
    vec4 a = dodecahedronAxisDistance(p);
    vec3 axis = a.xyz;
    float dist = a.a;
    mat3 m = rotationMatrix(axis, dist * amount);
    p *= m;
}

float model(vec3 p) {
    # ifndef DEBUG
        float wobble = sin(PI/2. * t);
           float wobbleX2 = sin(PI/2. * t*2.);
        pR(p.xy, wobbleX2 * .05);
        pR(p.xz, wobbleX2 * .05);
        float a = -wobble * 3.;
        pTwistDodecahedron(p, a);
    # endif
    return fDodecahedron(p, 1.);
}

// Spectrum from 0 - 1
// Brightens for values over 1
// Darkens for values below 0
vec3 debugSpectrum(float n) {
    vec3 c = spectrum(n);
    c *= 1. + min(sign(n), .0) * .3;
    c *= 1. + max(sign(n - 1.), 0.);
    return c;
}

vec3 material(vec3 p, vec3 norm, vec3 ref) {
    //return norm * 0.5 + 0.5;
    # ifdef DEBUG
        vec4 a = dodecahedronAxisDistance(p);
        float dist = a.a;
        return debugSpectrum(dist);
    # else
        return norm * 0.5 + 0.5;
    # endif
}

float debugPlane(vec3 p) {
    return 1000.;
    float xz = max(
        fPlane(p, vec3(0,1,0), 0.),
        -fPlane(p, vec3(0,1,0), 0.)
    );
    //return xz;
    float xy = max(
        fPlane(p, vec3(0,0,1), 0.),
        -fPlane(p, vec3(0,0,1), 0.)
    );
    //return xy;
    float yz = max(
        fPlane(p, vec3(1,0,0), 0.),
        -fPlane(p, vec3(1,0,0), 0.)
    );
    float d = min(min(xz, xy), yz);
    return max(d, length(p) - 1.);
}

// The MINIMIZED version of https://www.shadertoy.com/view/Xl2XWt

const float MAX_TRACE_DISTANCE = 30.0;           // max trace distance
const float INTERSECTION_PRECISION = 0.001;        // precision of the intersection
const int NUM_OF_TRACE_STEPS = 100;

// checks to see which intersection is closer
// and makes the y of the vec2 be the proper id
vec2 opU( vec2 d1, vec2 d2 ){
    return (d1.x<d2.x) ? d1 : d2;
}

//--------------------------------
// Modelling
//--------------------------------
vec2 map( vec3 p ){
    vec2 res = vec2(model(p), 1.);
        res = opU(res, vec2(debugPlane(p), 2.));
    return res;
}

vec2 calcIntersection( in vec3 ro, in vec3 rd ){

    float h =  INTERSECTION_PRECISION*2.0;
    float t = 0.0;
    float res = -1.0;
    float id = -1.;

    for( int i=0; i< NUM_OF_TRACE_STEPS ; i++ ){

        if( h < INTERSECTION_PRECISION || t > MAX_TRACE_DISTANCE ) break;
        vec2 m = map( ro+rd*t );
        h = m.x;
        t += h;
        id = m.y;
    }

    if( t < MAX_TRACE_DISTANCE ) res = t;
    if( t > MAX_TRACE_DISTANCE ) id =-1.0;

    return vec2( res , id );
}

//----
// Camera Stuffs
//----
mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

void doCamera(out vec3 camPos, out vec3 camTar, out float camRoll, in float time, in vec2 mouse) {

    float x = mouse.x;
    float y = mouse.y;
    
    x += .68;
    y += .44;
    
    float dist = 3.3;
    float height = 0.;
    camPos = vec3(0,0,-dist);
    vec3 axisY = vec3(0,1,0);
    vec3 axisX = vec3(1,0,0);
    mat3 m = rotationMatrix(axisY, -x * PI * 2.);
    axisX *= m;
    camPos *= m;
    m = rotationMatrix(axisX, -(y -.5) * PI*2.);
    camPos *= m;
    camPos.y += height;
    camTar = -camPos + vec3(.0001);
    camTar.y += height;
}

// Calculates the normal by taking a very small distance,
// remapping the function, and getting normal for that
vec3 calcNormal( in vec3 pos ){

    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

//
// interesting part starts here
//
// the meter uses the "fusion" gradient, which goes from dark magenta (0) to white (1)
// (often seen in heatmaps in papers etc)
//

vec3 fusion(float x) {
    float t = clamp(x,0.0,1.0);
    return clamp(vec3(sqrt(t), t*t*t, max(sin(PI*1.75*t), pow(t, 12.0))), 0.0, 1.0);
}

// HDR version
vec3 fusionHDR(float x) {
    float t = clamp(x,0.0,1.0);
    return fusion(sqrt(t))*(0.5+2.*t);
}

//
// distance meter function. needs a bit more than just the distance
// to estimate the zoom level that it paints at.
//
// if you have real opengl, you can additionally use derivatives (dFdx, dFdy)
// to detect discontinuities, i had to strip that for webgl
//
// visualizing the magnitude of the gradient is also useful
//

vec3 distanceMeter(float dist, float rayLength, vec3 rayDir, float camHeight) {
    float idealGridDistance = 20.0/rayLength*pow(abs(rayDir.y),0.8);
    float nearestBase = floor(log(idealGridDistance)/log(10.));
    float relativeDist = abs(dist/camHeight);
    
    float largerDistance = pow(10.0,nearestBase+1.);
    float smallerDistance = pow(10.0,nearestBase);
   
    vec3 col = fusionHDR(log(1.+relativeDist));
    col = max(vec3(0.),col);
    if (sign(dist) < 0.) {
        col = col.grb*3.;
    }

    float l0 = (pow(0.5+0.5*cos(dist*PI*2.*smallerDistance),10.0));
    float l1 = (pow(0.5+0.5*cos(dist*PI*2.*largerDistance),10.0));
    
    float x = fract(log(idealGridDistance)/log(10.));
    l0 = mix(l0,0.,smoothstep(0.5,1.0,x));
    l1 = mix(0.,l1,smoothstep(0.0,0.5,x));

    col.rgb *= 0.1+0.9*(1.-l0)*(1.-l1);
    return col;
}

vec3 render( vec2 res , vec3 ro , vec3 rd ){

    vec3 color = vec3(.04,.045,.05);
    color = vec3(.7, .8, .8);
    vec3 pos = ro + rd * res.x;

    if (res.y == 1.){
        vec3 norm = calcNormal( pos );
        vec3 ref = reflect(rd, norm);
        color = material(pos, norm, ref);
    } else if (res.y == 2.) {
        float dist = model(pos);
          //float ray_len = length(rd * res.x);
          color = distanceMeter(dist, dist*2., vec3(1.), 2.);
    }

  return color;
}

void main(void)
{
    initIcosahedron();
    t = time - .25;
    t = mod(t, 4.);

    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy / resolution.xy;

    vec3 camPos = vec3( 0., 0., 2.);
    vec3 camTar = vec3( 0. , 0. , 0. );
    float camRoll = 0.;

    // camera movement
    doCamera(camPos, camTar, camRoll, time, m);

    // camera matrix
    mat3 camMat = calcLookAtMatrix( camPos, camTar, camRoll );  // 0.0 is the camera roll

    // create view ray
    vec3 rd = normalize( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length

    vec2 res = calcIntersection( camPos , rd  );

    vec3 color = render( res , camPos , rd );

    glFragColor = vec4(color,1.0);
}
