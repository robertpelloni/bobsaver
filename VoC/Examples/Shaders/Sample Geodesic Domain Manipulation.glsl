#version 420

// original https://www.shadertoy.com/view/4tG3zW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
float t;

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
// HG_SDF
// https://www.shadertoy.com/view/Xs3GRB
// --------------------------------------------------------

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
    return dot(p, n) + distanceFromOrigin;
}

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
float fCone(vec3 p, float radius, float height) {
    vec2 q = vec2(length(p.xz), p.y);
    vec2 tip = q - vec2(0, height);
    vec2 mantleDir = normalize(vec2(height, radius));
    float mantle = dot(tip, mantleDir);
    float d = max(mantle, -q.y);
    float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
    
    // distance to tip
    if ((q.y > height) && (projected < 0.)) {
        d = max(d, length(tip));
    }
    
    // distance to base ring
    if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
        d = max(d, length(q - vec2(radius, 0)));
    }
    return d;
}

float fCone(vec3 p, float radius, float height, vec3 direction, float offset) {
    p -= direction * offset;
    p = reflect(p, normalize(mix(vec3(0,1,0), -direction, .5)));
    //p -= vec3(0,height,0);
    return fCone(p, radius, height);
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

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
    float s = sign(p);
    p = abs(p)-dist;
    return s;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float p, float size, float start, float stop) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p+halfsize, size) - halfsize;
    if (c > stop) { //yes, this might not be the best thing numerically.
        p += size*(c - stop);
        c = stop;
    }
    if (c <start) {
        p += size*(c - start);
        c = start;
    }
    return c;
}

// --------------------------------------------------------
// knighty
// https://www.shadertoy.com/view/MsKGzw
// --------------------------------------------------------

int Type=5;
vec3 nc,pab,pbc,pca;
void initIcosahedron() {//setup folding planes and vertex
    float cospin=cos(PI/float(Type)), scospin=sqrt(0.75-cospin*cospin);
    nc=vec3(-0.5,-cospin,scospin);//3rd folding plane. The two others are xz and yz planes
    pab=vec3(0.,0.,1.);
    pbc=vec3(scospin,0.,0.5);//No normalization in order to have 'barycentric' coordinates work evenly
    pca=vec3(0.,scospin,cospin);
    pbc=normalize(pbc);    pca=normalize(pca);//for slightly better DE. In reality it's not necesary to apply normalization :) 
}

// --------------------------------------------------------
// MAIN
// --------------------------------------------------------

// Barycentric to Cartesian 
vec3 bToC(vec3 A, vec3 B, vec3 C, vec3 barycentric) {
    return barycentric.x * A + barycentric.y * B + barycentric.z * C;
}

// Repeat space to form subdivisions of an icosahedron
// Return normal of the face
vec3 pIcosahedron(inout vec3 p, int subdivisions) {
    p = abs(p);
    pReflect(p, nc, 0.);
    p.xy = abs(p.xy);
    pReflect(p, nc, 0.);
    p.xy = abs(p.xy);
    pReflect(p, nc, 0.);
    
    if (subdivisions > 0) {

        vec3 A = pbc;
           vec3 C = reflect(A, normalize(cross(pab, pca)));
        vec3 B = reflect(C, normalize(cross(pbc, pca)));
       
        vec3 n;

        // Fold in corner A 
        
        float d = .5;
        
        vec3 p1 = bToC(A, B, C, vec3(1.-d, .0, d));
        vec3 p2 = bToC(A, B, C, vec3(1.-d, d, .0));
        n = normalize(cross(p1, p2));
        pReflect(p, n, 0.);
        
        if (subdivisions > 1) {

            // Get corners of triangle created by fold

            A = reflect(A, n);
            B = p1;
            C = p2;
            
            // Fold in corner A

            p1 = bToC(A, B, C, vec3(.5, .0, .5));
            p2 = bToC(A, B, C, vec3(.5, .5, .0));
            n = normalize(cross(p1, p2));
            pReflect(p, n, 0.);
            

            // Fold in corner B
            
            p2 = bToC(A, B, C, vec3(.0, .5, .5));
            p1 = bToC(A, B, C, vec3(.5, .5, .0));
            n = normalize(cross(p1, p2));
            pReflect(p, n, 0.);
        }
    }
    
    return pca;
}

// Normal for the perpendicular bisector plane of two points
vec3 bisector(vec3 a, vec3 b) {
    return normalize(cross(
        mix(a, b, .5),
        cross(a, b)
    ));
}

// Repeat space to form subdivisions of a dodecahedron
// Return normal of the face
vec3 pDodecahedron(inout vec3 p, int subdivisions) {
    p = abs(p);
    pReflect(p, nc, 0.);
    p.xy = abs(p.xy);
    pReflect(p, nc, 0.);
    p.xy = abs(p.xy);
    pReflect(p, nc, 0.);

    vec3 A;
    vec3 B;
    vec3 n;
    
    if (subdivisions == 1) {

        A = pbc;
        B = pab;
        n = bisector(A, B);
        pReflect(p, n, 0.);
    }
    
    if (subdivisions == 2) {

        vec3 pcai = pca * vec3(-1,-1,1);

        A = pbc;
        B = normalize(pcai + pca + pbc);
        n = bisector(A, B);
        pReflect(p, n, 0.);
        
        A = pbc;
        B = reflect(pca, n);
        n = bisector(A, B);
        pReflect(p, n, 0.);
    }
    
    return pbc;
}

float face(vec3 p, vec3 n, float s) {
    float d = 1000.;
    float part;
    
    float spikeSize = .08 + (2. - s) * .13;
    part = fCone(p, spikeSize, .8, n, .5);
    d = min(d, part);

    part = fPlane(p, n, -.9);
    d = min(d, part);

    return d;
}

float model(vec3 p) {
    float spacing = 2.8;
    p.x += spacing;
    float u = pModInterval1(p.x, spacing, 0., 2.);
    float v = pMirror(p.y, spacing / 2.);
    
    if (v < 0.) {
        vec3 n = pDodecahedron(p, int(u));
        return face(p, n, u);
    }

       vec3 n = pIcosahedron(p, int(u));
    return face(p, n, u);
}

// The MINIMIZED version of https://www.shadertoy.com/view/Xl2XWt

const float MAX_TRACE_DISTANCE = 20.0;           // max trace distance
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

void pRoll(inout vec3 p) {
    //return;
    float s = 5.;
    float d = 0.01;
    float a = sin(t * s) * d;
    float b = cos(t * s) * d;
    pR(p.xy, a);
    pR(p.xz, a + b);
    pR(p.yz, b);
}

vec2 map( vec3 p ){  
    pRoll(p);
    vec2 res = vec2(model(p), 1.);
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
        
    float dist = 6.4;
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
    camRoll = 0.;
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

vec3 render( vec2 res , vec3 ro , vec3 rd ){

    vec3 color = vec3(.04,.045,.05);

    vec3 pos = ro + rd * res.x;

    if (res.y == 1.){
        vec3 norm = calcNormal( pos );
        vec3 ref = reflect(rd, norm);
        color = norm * 0.5 + 0.5;
    }

  return color;
}

void main(void)
{
    t = time;
    //t = mod(t/2., 1.);
    
    initIcosahedron();
    
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
