#version 420

// original https://www.shadertoy.com/view/4dVcRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//nebula params

#define nebula

#define marchingIters 20
#define cloudBrightness 75.0
#define rungeKuttaIters 5
//vector field from https://en.wikipedia.org/wiki/Hopf_fibration#Fluid_mechanics
#define A -75.75
#define B 0.5

//blackhole params

#define blackhole
#define lensing

//4G/c^2 where G is the gravitational constant and c is the speed of light
#define forGc2 2.970357293242085e-27
#define blackholeMass 1e26
#define blackholeRadius 0.5*forGc2*blackholeMass //Schwarschild radius

const float pi = 4.0*atan(1.0);
const float isqrt2 = inversesqrt(2.0);

vec4 makeQuat(vec3 axis, float t){
    t *= 0.5;
    vec2 tr = sin(vec2(t, t + 0.5*pi));
    return vec4(tr.x*normalize(axis), tr.y);
}

vec3 Rotate(vec4 q, vec3 v){
    vec3 t = 2.*cross(q.xyz, v);
    return v + q.w*t + cross(q.xyz, t);
}

vec3 r(vec3 v, vec2 r){
    vec4 t = sin(vec4(r, r + 1.5707963268));
    float g = dot(v.yz, t.yw);
    return vec3(v.x * t.z - g * t.x,
                v.y * t.w - v.z * t.y,
                v.x * t.x + g * t.z);
}

//Thanks knarkowicz
//https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec2 OctWrap(vec2 v){
    return vec2((1.0 - abs(v.y))*(v.x >= 0.0 ? 1.0 : -1.0),
                (1.0 - abs(v.x))*(v.y >= 0.0 ? 1.0 : -1.0));
}
 
vec2 encode(vec3 n){
    n /= ( abs( n.x ) + abs( n.y ) + abs( n.z ) );
    n.xy = n.z >= 0.0 ? n.xy : OctWrap( n.xy );
    n.xy = n.xy * 0.5 + 0.5;
    return n.xy;
}

//modified Lambert-Azimuthal projection
vec2 proj(vec3 v){return inversesqrt(.5 * (1.0 + abs(v.z)) * abs(v.xy));}

float hash13(vec3 p){
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise3(vec3 x){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix(hash13(p+vec3(0,0,0)), 
                       hash13(p+vec3(1,0,0)),f.x),
                   mix(hash13(p+vec3(0,1,0)), 
                       hash13(p+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash13(p+vec3(0,0,1)), 
                       hash13(p+vec3(1,0,1)),f.x),
                   mix(hash13(p+vec3(0,1,1)), 
                       hash13(p+vec3(1,1,1)),f.x),f.y),f.z);
}

//distance to inner ring of Hopf fibration (unit circle in xy pllane centered at origin)
float dRing(vec3 p){return length(vec2(length(p.xy) - 1.0, p.y));}

vec3 velocity(vec3 p){
    float a = dRing(p);
    float a2 = a*a;
    float r = dot(p, p);
    float ar = a2 + r;
    return A*vec3(2.0*(-a*p.y + p.x*p.z), 2.0*(a*p.x - p.y*p.z), a - r)/(ar*ar);
}

float density(vec3 p){
    float a = dRing(p);
    return 3.0*B/(a*a + dot(p, p));
}

vec2 pressureAndDensity(vec3 p){
    float d = density(p);
    return vec2(-A*A*0.333333*d*d*d/(B*B), d);
}

vec2 logistic(vec2 v){
    return vec2(16.0/(1.0 + 10.0*exp(-0.75*v.x)),
                1.0/(1.0 + 10.0*exp(-1.95*v.y)));
}

vec3 gaussian(float x){
    vec3 disp = x - vec3(0.3, 0.6, 0.9);
    return exp(-16.0*disp*disp - 4.0);
}

vec3 makeColor(vec3 p){
    vec2 pd = pressureAndDensity(p);
    pd = logistic(pd);
    float fn = cloudBrightness*pd.y;
    return fn*vec3(1.0, 0.75, 1.0)*gaussian(pd.x);
}

vec3 approxFlow(vec3 p, float t){
    t /= float(rungeKuttaIters);
    for(int i = 0; i < rungeKuttaIters; ++i) {
            vec3 k1 = -velocity(p);
            vec3 k2 = -velocity(p + 0.5*k1*t);
            vec3 k3 = -velocity(p + 0.5*k2*t);
            vec3 k4 = -velocity(p + k3*t);
            p += 0.161616*t*(k1 + 2.0*k2 + 2.0*k2 + k3);
    }
    
    return p;
}

vec3 interpolateColor(vec3 p){
    float t1 = fract(0.5*time);
    float t2 = fract(t1 + 0.5);
    vec3 c1 = makeColor(approxFlow(p, t1 + 0.3));
    vec3 c2 = makeColor(approxFlow(p, t2 + 0.3));
    t1 = 2.0*abs(t1 - 0.5);
    return mix(c1, c2, t1);
}

//vec3 galaxies(vec3 rd){return texture(iChannel0, encode(rd)).rgb;}

bool iBlackhole(vec3 ro, vec3 rd){
    float loc = dot(rd, ro);
    return loc*loc + 2.25*blackholeRadius*blackholeRadius > dot(ro, ro);
}

float dBlackholePlane(vec3 ro, vec3 rd, vec3 n){return -dot(ro, n)/dot(rd, n);}

vec3 render(vec3 ro, vec3 rd){

    vec3 nml = normalize(ro);

    vec3 col = vec3(0);
    bool hit = iBlackhole(ro, rd);
    float plane = dBlackholePlane(ro, rd, nml);

    float stepsize = 2.0*plane/float(marchingIters);

    int fstIters = marchingIters/2;
    #ifdef blackhole
    if(hit) fstIters = marchingIters/2 - 1; //avoid rendering inside the blackhole
    #endif

    vec3 pos = ro + stepsize*rd;

    #ifdef nebula
    //march until the plane containing the blackhole center is reached
    for(int n = 0; n < fstIters; n++){
        col += interpolateColor(pos);
        pos += stepsize*rd;
    }
    #endif
    
    #ifdef lensing
    //then change direction
    float r = length(pos);
    vec3 axis = cross(pos, nml);
    //angle of deflection is 4MG/(rc^2)
    float angle = -forGc2*blackholeMass/r;
    vec4 quaternion = makeQuat(axis, angle);
    rd = Rotate(quaternion, rd);
    #endif
    
    #ifdef blackhole
    if(hit) return col;
    #ifdef nebula
    else {
        for(int n = 0; n < marchingIters/2; n++){
            col += interpolateColor(pos);

            pos += stepsize*rd;
        }
    #endif
    }
    #else
    for(int n = 0; n < marchingIters/2; n++){
        col += interpolateColor(pos);
        pos += stepsize*rd;
    }
    #endif
    return col;
}

void main(void) {
    glFragColor = vec4(0.0);
    vec2 xy = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 ro = vec3(0.0, 0.0, -0.5*float(marchingIters)*blackholeRadius);
    vec3 rd = normalize(vec3(xy, 2.5));
    vec2 m = (2.0 * mouse*resolution.xy.xy - resolution.xy) / resolution.y;
    m *= 2.0;
    
    rd = r(rd, m + 0.1*time);
    ro = r(ro, m + 0.1*time);
    glFragColor.rgb = render(ro, rd);
}
