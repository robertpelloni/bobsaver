#version 420

// original https://www.shadertoy.com/view/3tKGD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-----------------CONSTANTS MACROS-----------------

#define PI 3.14159265359
#define E 2.7182818284
#define GR 1.61803398875
#define MAX_DIM (max(resolution.x,resolution.y))
#define FAR (PI*2.0)

//-----------------UTILITY MACROS-----------------

#define time ((sin(float(__LINE__))/PI/GR+1.0)*time+1000.0+last_height)
#define sphereN(uv) (clamp(1.0-length(uv*2.0-1.0), 0.0, 1.0))
#define clip(x) (smoothstep(0.0, 1.0, x))
#define TIMES_DETAILED (1.0)
#define angle(uv) (atan(uv.y, uv.x))
#define angle_percent(uv) ((angle(uv)/PI+1.0)/2.0)
#define hash(p) (fract(sin(vec2( dot(p,vec2(127.5,313.7)),dot(p,vec2(239.5,185.3))))*43458.3453))

#define flux(x) (vec3(cos(x),cos(4.0*PI/3.0+x),cos(2.0*PI/3.0+x))*.5+.5)
#define rotatePoint(p,n,theta) (p*cos(theta)+cross(n,p)*sin(theta)+n*dot(p,n) *(1.0-cos(theta)))
#define rormal(x) (normalize(sin(vec3(time, time/GR, time*GR))*.25+.5))
#define circle(x) (vec2(cos((x)*PI), sin((x)*PI)))
#define saw(x) fract( sign( 1.- mod( abs(x), 2.) ) * abs(x) )

float last_height = 0.0;
float beat = 0.0;

float sphere(vec3 rp, vec3 rd, vec3 bp, float r) {
    
    vec3 oc = rp - bp;
    float b = 2.0 * dot(rd, oc);
    float c = dot(oc, oc) - r*r;
    float disc = b * b - 4.0 * c;

    if (disc < 0.0)
        return 0.0;

    // compute q as described above
    float q;
    if (b < 0.0)
        q = (-b - sqrt(disc))/2.0;
    else
        q = (-b + sqrt(disc))/2.0;

    float t0 = q;
    float t1 = c / q;

    // make sure t0 is smaller than t1
    if (t0 > t1) {
        // if t0 is bigger than t1 swap them around
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    
    return (t1-t0)/r;
}

float line(vec3 rp, vec3 rd, vec3 a, vec3 b, float r) {
    vec3 pa = rp - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    
    vec3 ray = rd;
    vec3 ray2 = normalize(b-a);

    float a1 = dot(ray,ray);
    float b1 = dot(ray,ray2);
    float c = dot(ray2,ray2);
    float d = dot(ray,rp-a);
    float e = dot(rp-a,ray2);

    float t1 = (b1*e-c*d)/(a1*c-b1*b1);
    float t2 = (a1*e-b1*d)/(a1*c-b1*b1);

    float dist = length((rp+ray*t1)-(a+ray2*t2));
    return dist > r || t2 < r || t2 > length(a-b)+r? 0.0 : 1.0-dist/r;
}

const int NUM_ANGLES = 5;
const int ELBOWS = 0;
const int WRISTS = 1;
const int FINGERS = 2;
const int KNEES = 3;
const int ANKLES = 4;
// stance structure:
//{
//    vec4(leftLegOmega, leftLegTheta, rightLegOmega, rightLegTheta)),
//    vec4(relativeLeftElbowOmega, relativeLeftElbowTheta, relativeRightElbowOmega, relativeRightElbowTheta)),
//    vec4(relativeLeftWristOmega, relativeLeftWristTheta, relativeRightWristOmega, relativeRightWristTheta)),
//    vec4(relativeLeftFingersOmega, relativeLeftFingersTheta, relativeRightFingersOmega, relativeRightFingersTheta)),
//    vec4(leftLegOmega, LeftLegTheta, rightLegOmega, rightLegTheta)),
//    vec4(relativeLeftKneeOmega, relativeLeftKneeTheta, relativeRightKneeOmega, relativeRightKneeTheta)),
//    vec4(relativeLeftAnkleOmega, relativeLeftAnkleTheta, relativeRightAnkleOmega, relativeRightAnkleTheta)),
//}
//
// Vertices
const vec3 lbf = vec3(-0.5,-0.5,-0.5);
const vec3 rbf = vec3( 0.5,-0.5,-0.5);
const vec3 lbb = vec3(-0.5,-0.5, 0.5);
const vec3 rbb = vec3( 0.5,-0.5, 0.5);

const vec3 ltf = vec3(-0.5, 0.5,-0.5);
const vec3 rtf = vec3( 0.5, 0.5,-0.5);
const vec3 ltb = vec3(-0.5, 0.5, 0.5);
const vec3 rtb = vec3( 0.5, 0.5, 0.5);

float dancer(vec3 p, vec3 rd) {
    
float t = mod(time,1.0);
float s = sin(time)/PI/GR;

vec3 lbfi = vec3(-0.5+s,-0.5+s,-0.5+s);
vec3 rbfi = vec3( 0.5-s,-0.5+s,-0.5+s);
vec3 lbbi = vec3(-0.5+s,-0.5+s, 0.5-s);
vec3 rbbi = vec3( 0.5-s,-0.5+s, 0.5-s);

vec3 ltfi = vec3(-0.5+s, 0.5-s,-0.5+s);
vec3 rtfi = vec3( 0.5-s, 0.5-s,-0.5+s);
vec3 ltbi = vec3(-0.5+s, 0.5-s, 0.5-s);
vec3 rtbi = vec3( 0.5-s, 0.5-s, 0.5-s);

vec3 lbf_lbfi = mix(lbf,lbfi,t);
vec3 ltf_ltfi = mix(ltf,ltfi,t);
vec3 lbb_lbbi = mix(lbb,lbbi,t);
vec3 ltb_ltbi = mix(ltb,ltbi,t);

vec3 rbb_lbb = mix(rbb,lbb,t);
vec3 rbf_lbf = mix(rbf,lbf,t);
vec3 rtf_ltf = mix(rtf,ltf,t);
vec3 rtb_ltb = mix(rtb,ltb,t);

vec3 lbfi_rbfi = mix(lbfi,rbfi,t);
vec3 lbbi_rbbi = mix(lbbi,rbbi,t);
vec3 ltfi_rtfi = mix(ltfi,rtfi,t);
vec3 ltbi_rtbi = mix(ltbi,rtbi,t);

vec3 rbbi_rbb = mix(rbbi,rbb,t);
vec3 rbfi_rbf = mix(rbfi,rbf,t);
vec3 rtfi_rtf = mix(rtfi,rtf,t);
vec3 rtbi_rtb = mix(rtbi,rtb,t);
    
    float d = 0.0;

    float radius = .025;
    // outside
    d += line(p,rd,lbf_lbfi,rbf_lbf,radius);
    d += line(p,rd,lbb_lbbi,rbb_lbb,radius);
    d += line(p,rd,ltf_ltfi,rtf_ltf,radius);
    d += line(p,rd,ltb_ltbi,rtb_ltb,radius);

    d += line(p,rd,lbf_lbfi,lbb_lbbi,radius);
    d += line(p,rd,ltf_ltfi,ltb_ltbi,radius);
    d += line(p,rd,lbf_lbfi,ltf_ltfi,radius);
    d += line(p,rd,lbb_lbbi,ltb_ltbi,radius);

    d += line(p,rd,rbf_lbf,rbb_lbb,radius);
    d += line(p,rd,rtf_ltf,rtb_ltb,radius);
    d += line(p,rd,rbf_lbf,rtf_ltf,radius);
    d += line(p,rd,rbb_lbb,rtb_ltb,radius);

    // inside
    d += line(p,rd,lbfi_rbfi,lbbi_rbbi,radius);
    d += line(p,rd,ltfi_rtfi,ltbi_rtbi,radius);
    d += line(p,rd,lbfi_rbfi,ltfi_rtfi,radius);
    d += line(p,rd,lbbi_rbbi,ltbi_rtbi,radius);

    d += line(p,rd,lbbi_rbbi,rbbi_rbb,radius);
    d += line(p,rd,lbfi_rbfi,rbfi_rbf,radius);
    d += line(p,rd,ltfi_rtfi,rtfi_rtf,radius);
    d += line(p,rd,ltbi_rtbi,rtbi_rtb,radius);

    d += line(p,rd,rbfi_rbf,rtfi_rtf,radius);
    d += line(p,rd,rbbi_rbb,rtbi_rtb,radius);
    d += line(p,rd,rbfi_rbf,rbbi_rbb,radius);
    d += line(p,rd,rtfi_rtf,rtbi_rtb,radius);

    // connections
    d += line(p,rd,rtbi_rtb,rtb_ltb,radius);
    d += line(p,rd,rbfi_rbf,rbf_lbf,radius);
    d += line(p,rd,rbbi_rbb,rbb_lbb,radius);
    d += line(p,rd,rtfi_rtf,rtf_ltf,radius);
    
    d += line(p,rd,ltfi_rtfi,ltf_ltfi,radius);
    d += line(p,rd,ltbi_rtbi,ltb_ltbi,radius);
    d += line(p,rd,lbfi_rbfi,lbf_lbfi,radius);
    d += line(p,rd,lbbi_rbbi,lbb_lbbi,radius);

    return d;
}

vec4 draw(vec3 ro, vec3 rd, vec2 uv0) {
    float depth = dancer(ro, rd);
    
    float weight = clamp(depth, 0.0, 1.0);;
    
    return vec4(flux(depth+time*PI)*weight, weight);//clamp(+(1.0-weight)*sample, 0.0, 1.0);
}

void main(void) {
    
    //coordinate system
    vec2 uv0 = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (uv0* 2.0 - 1.0)*vec2(resolution.x / resolution.y, 1.0);
    
    //camera
    vec3 rd = normalize(vec3(uv, -1.0));
    vec3 ro = vec3(0.0, 0.0, 1.0);
    
    float t = time;
    vec3 axis = rormal();//vec3(0.0, 1.0, 0.0);
    
    ro = rotatePoint(ro, axis, t);
    rd = rotatePoint(rd, axis, t);
    ro *= FAR/PI;
    
    glFragColor = draw(ro, rd, uv0);
}
