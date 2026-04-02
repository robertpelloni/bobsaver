#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tt2yWW

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Mario Head by Philippe Desgranges
// Email: Philippe.desgranges@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

#define MAX_DST 45.0
#define MIN_DST 0.008
#define S(a,b,c) smoothstep(a,b,c)
#define sat(a) clamp(a,0.0,1.0)
#define ZERO (min(frames,0))

//Material regions
#define SKIN             0.0
#define CAP               1.0
#define CAP2               2.0
#define HAIR            3.0
#define HAIR2            4.0
#define EYES            5.0
#define INSIDE_MOUTH     6.0
#define    TEETH            7.0

#define pi 3.14159265359
#define pi2 (pi * 2.0)
#define halfPi (pi * 0.5)
#define degToRad (pi / 180.0)

mat4 scaleMatrix( in vec3 sc ) {
    return mat4(sc.x, 0,    0,    0,
                 0,      sc.y,    0,    0,
                0,      0,     sc.z,    0,
                0,      0,  0,    1);
}

mat4 rotationX( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat4(1.0, 0,     0,    0,
                 0,      c,    -s,    0,
                0,      s,     c,    0,
                0,      0,  0,    1);
}

mat3 rotationX3( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat3(1.0, 0,     0,
                 0,      c,    -s,
                0,      s,     c);
}

mat4 rotationY( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat4( c, 0,     s,    0,
                  0,    1.0, 0,    0,
                -s,    0,     c,    0,
                 0, 0,     0,    1);
}

mat3 rotationY3( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
    return mat3( c, 0,     s,
                  0,    1.0, 0,
                -s,    0,     c);
}

mat4 rotationZ( in float angle ) {
    float c = cos(angle);
    float s = sin(angle);
    
    return mat4(c, -s,    0,    0,
                 s,    c,    0,    0,
                0,    0,    1,    0,
                0,    0,    0,    1);
}

mat4 translate( in vec3 p) {

    return mat4(1,  0,    0,    0,
                 0,    1,    0,    0,
                0,    0,    1,    0,
                p.x, p.y, p.z, 1);
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdSphere(vec3 pos, vec3 center, float radius)
{
    return length(pos - center) - radius;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float dot2( vec2 v ) { return dot(v,v); }

vec2 combineMin(vec2 a, vec2 b)
{
    return (a.x < b.x)? a : b;
}

vec2 combineMax(vec2 a, vec2 b)
{
    return (a.x > b.x)? a : b;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoidPrecise( in vec3 p, in vec3 r ) // approximated
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k1 = length(p/r);
    return (k1-1.0)*min(min(r.x,r.y),r.z);
}

// Some hash function 2->1
float N2(vec2 p)
{    // Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    p = mod(p, vec2(1456.2346));
    vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// A 2d Noise
float Noise2(vec2 uv)
{
    vec2 corner = floor(uv);
    float c00 = N2(corner + vec2(0.0, 0.0));
    float c01 = N2(corner + vec2(0.0, 1.0));
    float c11 = N2(corner + vec2(1.0, 1.0));
    float c10 = N2(corner + vec2(1.0, 0.0));
    
    vec2 diff = fract(uv);
    
    diff = diff * diff * (vec2(3) - vec2(2) * diff);
    //diff = smoothstep(vec2(0), vec2(1), diff);
    
    return mix(mix(c00, c10, diff.x), mix(c01, c11, diff.x), diff.y);
}

// 1d Noise, y is seed
float Noise1(float x, float seed)
{
    vec2 uv = vec2(x, seed);
    vec2 corner = floor(uv);
    float c00 = N2(corner + vec2(0.0, 0.0));
    float c10 = N2(corner + vec2(1.0, 0.0));
    
    float diff = fract(uv.x);
    
    diff = diff * diff * (3.0 - 2.0 * diff);
    
    return mix(c00, c10, diff) - 0.5;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

        
// All the parametters for an animation pose
struct KeyFrame
{
    vec2 eyePos;
    float eyelidsOpen;
    float eyeOpening;
    float browBend;
    float moustacheBend;
    float mouthOpenVert;
    float mouthOpenHoriz;
    float bendX;
    float twistX;
    vec2 headRotation;
};

// Linear interpolation between two animation frames
void mixKeyFrame(KeyFrame a, KeyFrame b, float ratio, out KeyFrame c)
{
    c.eyePos         = mix(a.eyePos            ,b.eyePos          ,ratio);
    c.eyelidsOpen     = mix(a.eyelidsOpen    ,b.eyelidsOpen      ,ratio);
    c.eyeOpening     = mix(a.eyeOpening        ,b.eyeOpening      ,ratio);
    c.browBend         = mix(a.browBend        ,b.browBend          ,ratio);
    c.moustacheBend  = mix(a.moustacheBend  ,b.moustacheBend  ,ratio);
    c.mouthOpenVert  = mix(a.mouthOpenVert  ,b.mouthOpenVert  ,ratio);
    c.mouthOpenHoriz = mix(a.mouthOpenHoriz ,b.mouthOpenHoriz ,ratio);
    c.bendX             = mix(a.bendX            ,b.bendX          ,ratio);
    c.twistX         = mix(a.twistX            ,b.twistX          ,ratio);
    c.headRotation     = mix(a.headRotation    ,b.headRotation      ,ratio);
}

// all matrices and offsets that needs to be pre-computed
// in order to keep the SDF relatively straightforward
struct MatSpace
{
    float twistLower;
    float twistX;
    float bendX;
    float moustacheBend;
    
    vec3 eyeRad;
    vec3 cheekPos;
    vec3 cheekRad;
    vec3 chinPos;
    vec3 noseRad;

    vec3 mouthPos;
    vec3 mouthRad;

    vec3 lipPos;
    float lipStretchX;
    float lipThickness;

    mat3 earMat;
    mat3 cap1Mat;
    mat3 cap2Mat;

    vec3 hairTip1;
    vec3 hairTip2;

    float browOffset;
    float browBend;

    vec3 teethPos;

    vec2 eyePos;
    float eyelidsOpen;
};

// Attributes of a PBR material
struct PBRMat
{
    vec3 albedo;
    float metalness;
    float roughness;
};

// Ditance to the Letter M (cap + bg)
float MDist(vec2 uvs)
{
    vec2 p = uvs;
    p.x = abs(p.x);
            

    float v = p.y - 0.7 - p.x;
    v = max(v, p.y - 2.6 + p.x * 1.8); 
    
    
    float v2 = p.y - 0.0 - p.x;
    v2 = max(v2, p.y - 1.6 + p.x * 2.35); 
    
    v = max(v, -v2);
    
    v = max(v, -p.y - 1.0 + p.x * 0.3);
    return v;
}
    

// Computes a PBR Material from material ID and world position
void GetColor(float id, vec3 pos, MatSpace ps, out PBRMat mat, out vec3 normalBend)
{   
    normalBend = vec3(0);
    
    if (id == SKIN)
    {
        mat = PBRMat(vec3(1.0, 0.8, 0.8), 0.1, 0.3);
    }
    else if (id == CAP)
    {
        float mMask = 0.0;
        
        if (pos.z < 0.0)
        {
            vec2 p = pos.xy - vec2(0.0, 8.0);
           
            float v = MDist(p);
            
            mMask = length(p * vec2(1.0, 1.2));
            mMask = S(2.3, 2.28, mMask);
            mMask *= S(-0.03, 0.03, v);
        }
     
        
        mat = PBRMat(mix(vec3(0.8, 0.0, 0.0), vec3(1,1,1), mMask) , 0.05, 1.0);
    }
    else if (id == CAP2)
    {
        mat = PBRMat(vec3(0.8, 0.0, 0.0), 0.05, 1.0);
    }
    else if (id == HAIR)
    {
        mat = PBRMat(vec3(0.5, 0.25, 0.05), 0.1, 0.5);
    }
    else if (id == HAIR2)
    {
        mat = PBRMat(vec3(0.25, 0.15, 0.02), 0.3, 0.2);
    }
    else if (id == EYES)
    {

        
        vec2 uvs = pos.xy;
        
        uvs.x -= 1.5 * sign(pos.x);
        uvs -=  ps.eyePos; // eye position
        
          float iris = length(uvs * vec2(1, 0.7));
        
        vec3 blue = vec3(0.3, 0.8, 1.0);
        vec3 blue2 = vec3(0.1, 0.2, 0.8);
        
        blue = mix(blue, blue2, S(0.1, 1.3, iris - uvs.y * 0.2));
        
        vec3 eyeCol = mix(blue, vec3(1, 1, 1), S(0.75, 0.8, iris));
        
        eyeCol *=  S(0.45, 0.5, iris);
        eyeCol +=  S(0.3, 0.2, length(uvs - vec2(0, 0.3))) * 3.0;
        
        float lidDst = abs(pos.y - 2.6) - ps.eyelidsOpen;
        
        float lid = S(0.001, 0.01, lidDst);
        
        eyeCol = mix(eyeCol, vec3(1.0, 0.8, 0.8) * S(-0.2, 0.2, lidDst), lid);
        
        mat = PBRMat(eyeCol, 0.0, 0.5);
    }
    else if (id == INSIDE_MOUTH)
    {
        mat = PBRMat(vec3(0.75, 0.0, 0.1), 0.05, 1.0);
    }
    else 
    {
        mat = PBRMat(vec3(1.0, 1.0, 1.0), 0.05, 1.0);
    }
    
    return;
}

// Some pprocedural animation functions

void HappyExpression(out KeyFrame res)
{
    float opening = Noise1(time, 444.0);
    res.eyeOpening = 1.0 + opening * 0.2;
    res.browBend = -opening * 0.2;
    res.moustacheBend = -opening * 0.15;//sin(time * 2.0) * 0.3;
    
    float smile = Noise1(time * 0.56, 447.0);
    
    res.mouthOpenVert =  0.01 - smile * 0.04;//sin(time * 3.0) * 0.04;
    res.mouthOpenHoriz = 0.01 + smile * 0.08;//-0.02;//sin(time) * 0.05;
    res.bendX = -0.1 -opening * 0.2;//sin(time) * 0.3;
    res.twistX = 0.0;//sin(time * 10.0) * 0.2;

    
    float eyelidsOpen = fract(time * 0.2) * 30.0;
                        
    res.eyelidsOpen = eyelidsOpen;
    
    float rotX = Noise1(time * 0.3, 14.0);
    res.headRotation = vec2(rotX * 0.5, opening * 0.3);
    
    res.eyePos = vec2(opening * 0.5, 3.0);
}

void AngryExpression(out KeyFrame res)
{
    float opening = Noise1(time, 444.0);
    res.eyeOpening = 0.6 + opening * 0.4;
    res.browBend = -opening * 0.4 - 0.4;
    
    
    float smile = Noise1(time * 0.56, 447.0);
    
    res.moustacheBend = 0.2 -  smile * 0.2;//sin(time * 2.0) * 0.3;
    
    res.mouthOpenVert =  0.02 - smile * 0.04;//sin(time * 3.0) * 0.04;
    res.mouthOpenHoriz = -0.02;// + smile * 0.08;//-0.02;//sin(time) * 0.05;
    res.bendX = 0.2 + opening * 0.1;//sin(time) * 0.3;
    

    res.twistX = Noise1(time * 0.3, 487.0) * 0.5;

    
    float eyelidsOpen = min(fract(time * 0.2) * 30.0, 0.8 +  res.twistX);
                        
    res.eyelidsOpen = eyelidsOpen;
    
    float rotY = Noise1(time * 1.5, 14.0);
    res.headRotation = vec2(-0.03, rotY * 0.3);
    
    res.eyePos = vec2(opening * 0.8, 3.2);
}

void LaughExpression(out KeyFrame res)
{
    float laugh = sin(time * 5.0) + sin(time * 16.34) * 0.5;
    
    float opening = Noise1(time, 444.0);
    res.eyeOpening = 0.6 + opening * 0.4;
    res.browBend = laugh * 0.3 + 0.1;
    
    float smile = Noise1(time * 1.56, 447.0);
    
    res.moustacheBend = -0.1 +  smile * 0.5;//sin(time * 2.0) * 0.3;
    
    res.mouthOpenVert =  0.03 + laugh * 0.02;//sin(time * 3.0) * 0.04;
    res.mouthOpenHoriz = - laugh * 0.02;// + smile * 0.08;//-0.02;//sin(time) * 0.05;
    res.bendX = -laugh * 0.2 + 0.05;

    res.twistX = 0.0;//Noise1(time * 0.3, 487.0) * 0.5;
                        
    res.eyelidsOpen = 0.0;
    
    res.headRotation = vec2(0.4 + laugh * 0.2, Noise1(time * 0.2, 444.0) * 1.2);
    
    res.eyePos = vec2(0.0, 4.0);
}

void AmazedExpression(out KeyFrame res)
{
    float hfNoise = Noise1(time * 4.0, 36.0);
      float opening = Noise1(time * 0.7, 444.0);
    res.eyeOpening = 1.3 + opening * 0.2;
    res.browBend = -opening * 0.2 + 0.1;
    res.moustacheBend = hfNoise * 0.05 - 0.05;//sin(time * 2.0) * 0.3;
    
    float smile = Noise1(time * 0.56, 447.0);
    
    res.mouthOpenVert =  0.04 - hfNoise * 0.01;//sin(time * 3.0) * 0.04;
    res.mouthOpenHoriz = 0.0 + smile * 0.02;//-0.02;//sin(time) * 0.05;
    res.bendX = -0.1;//sin(time) * 0.3;
    res.twistX = -opening * 0.1;//sin(time * 10.0) * 0.2;

    
    float eyelidsOpen = fract(time * 0.3) * 30.0;
                        
    res.eyelidsOpen = eyelidsOpen;
    
    
    
    float rotX = Noise1(time * 0.3, 14.0);
    res.headRotation = vec2(rotX * 0.5 + 0.15, opening * 0.3);
    
    res.eyePos = vec2(opening * 0.5 + hfNoise * 0.2, 3.8 );
}

// Chooses a random anim based on a [0 - 1] seed

void ExpressionForSeed(out KeyFrame res, float seed)
{
    if (seed < 0.25)
    {
        LaughExpression(res);
    }
    else if (seed < 0.5)
    {
       HappyExpression(res);
    }
    else if (seed < 0.75)
    {
       AmazedExpression(res);
    }
    else
    {
       AngryExpression(res);
    }
}

// Build all the matrices and offsets necessary to compute the SDF
// leaving all that in would lead to bad perfs and longer compile times
void buildMatSpace(KeyFrame frame, out MatSpace res)
{
    res.moustacheBend = frame.moustacheBend;
    res.twistLower = -0.4 + frame.mouthOpenVert * 0.5;
    res.twistX = frame.twistX;
    res.bendX = frame.bendX;
    res.moustacheBend = frame.moustacheBend;

    res.eyeRad = vec3(0.21, 0.37 * frame.eyeOpening, 0.20) * 0.5;
    res.cheekPos = vec3(0.2 + frame.mouthOpenHoriz * 0.5, -0.014 - frame.mouthOpenVert, -0.19);
    res.cheekRad = vec3(0.51, 0.55 + frame.mouthOpenVert * 0.5, 0.57) * 0.5;
    res.chinPos = vec3(0.0, -0.26 - frame.mouthOpenVert * 0.6, -0.22 - frame.mouthOpenVert * 1.0);
    res.noseRad = vec3(0.42 + frame.mouthOpenHoriz, 0.39 - frame.mouthOpenHoriz * 0.5, 0.41) * 0.5;

    res.mouthPos = vec3(0.0, -0.13 - frame.mouthOpenVert * 1.8, -0.41);
    res.mouthRad = vec3(0.32, 0.16 + frame.mouthOpenVert, 0.31) * 0.5;

    res.lipPos = vec3(0.0, -0.06 - frame.mouthOpenVert * 3.0, -0.36 - frame.mouthOpenVert * 1.5);
    res.lipStretchX = 1.0f - frame.mouthOpenHoriz * 7.0;
    res.lipThickness = 0.1 - frame.mouthOpenVert;

    res.earMat = rotationX3(-65.0 * degToRad + frame.mouthOpenHoriz);
    res.cap1Mat = rotationX3(30.0 * degToRad);
    res.cap2Mat = rotationX3(60.0 * degToRad);

    res.hairTip1 = vec3(0.45 - frame.mouthOpenVert * 0.6,0.06,-0.23);
    res.hairTip2 = vec3(0.42 - frame.mouthOpenVert * 0.25,0.19,-0.28);

    res.browOffset = (frame.eyeOpening - 1.0) * 0.15;
    res.browBend = frame.browBend;

    res.teethPos = vec3(0.0, -0.1 - frame.mouthOpenVert * 0.5, -0.2  - frame.mouthOpenVert);

    res.eyePos = frame.eyePos;
    res.eyelidsOpen = frame.eyelidsOpen;

}

// SDF of the scene
vec2 SDF(vec3 pos, MatSpace ps)
{   
      
    vec3 posUntwisted = pos * 0.1;
    
    //twist for th jaw
    float twist = S(-0.1, ps.twistLower, posUntwisted.y) * ps.twistX;
    
    pos = rotationY3(twist) * posUntwisted;

    pos.x = abs(pos.x); // face is symmetrical
    posUntwisted.x = abs(posUntwisted.x);
    
    // bend for the face (happy / sad)
    float bend = clamp(pos.x * pos.x * ps.bendX, -0.5, 0.5);
    
    pos.y += bend;
    
    // ellipsoids for the face
    float head = sdEllipsoid(pos - vec3(0.0, 0.22, 0.03), vec3(0.96, 1.18, 0.99) * 0.5);
    float cheek = sdEllipsoid(pos - ps.cheekPos, ps.cheekRad);
    float chin = sdEllipsoid(pos - ps.chinPos, vec3(0.41, 0.34, 0.38) * 0.5);
    
    // Nose (tapered ellipsoid)
    vec3 noseR = ps.noseRad;
    noseR.x += clamp(pos.y * 0.125, -0.05, 0.05);
    float nose = sdEllipsoid(pos - vec3(0.0, 0.13, -0.62), noseR);
    
    // holes for the eyes and mouth
    float eye = sdEllipsoidPrecise(pos - vec3(0.14, 0.27, -0.39), ps.eyeRad);
    
    vec3 mouthPos = pos;
    mouthPos.x *= ps.lipStretchX;
    float innerMouth = sdEllipsoid(mouthPos - ps.mouthPos, ps.mouthRad);
    
    // lower lip is a torus
    float lowerlip = sdTorus((mouthPos - ps.lipPos).xzy, vec2(0.15, ps.lipThickness));
    
       // ears too
    float ear = sdTorus(ps.earMat * (pos - vec3(0.5, 0.13, 0.07)).yzx, vec2(0.16, 0.07));
    
    // smooth combine all that stuff
    head = smin(head, chin, 0.06);
    head = smin(head, lowerlip, 0.02);
    head = smax(head, -innerMouth, 0.05);
    head = smax(head, -eye, 0.05);
    head = smin(head, cheek, 0.1);
    head = smin(head, nose, 0.06);
    head = smin(head, ear, 0.11);
    
    
    // The cap is also a bunch of eelipsoids
    vec3 cap1Pos = ps.cap1Mat * (pos - vec3(0, 0.8, -0.08));
    float cap = sdEllipsoid(cap1Pos, vec3(1.04, 0.69, 0.77) * 0.5);
    
    vec3 cap2Pos = ps.cap1Mat * (pos - vec3(0, 0.46, 0.24));
    cap = smin(cap, sdEllipsoid(cap2Pos, vec3(1.28, 0.66, 1.18) * 0.5), 0.27);
    
    vec3 cap3Pos = ps.cap2Mat * (pos - vec3(0.0, 0.89, 0.69));
    cap = smax(cap, -sdEllipsoid(cap3Pos, vec3(1.95, 0.71, 1.01) * 0.5), 0.09);
    
    // the visor is the intersection of two capsules
    vec3 vpos = pos;
    vpos.x *= 0.9; // sligtly scaled
    float visor = sdCapsule(vpos, vec3(0,0.25,0), vec3(0,0.15,-1.0), 0.5);
    
      float visorHollow =  -sdCapsule(vpos, vec3(0,0,0), vec3(0,0.2,-2.0), 0.56);
                              
    visor = smax(visor, visorHollow, 0.09);
     cap = max(cap, visorHollow);
    
    // side hair is two capsules
    float hair = sdCapsule(pos, vec3(0.40,0.39,-0.11), ps.hairTip1, 0.07);
    hair = smin(hair, sdCapsule(pos, vec3(0.39,0.37,-0.11), ps.hairTip2, 0.06), 0.03);
    
    // back hair is a bunch of allipsoids
    float backHair = sdEllipsoid(pos - vec3(0.0, -0.02, 0.43), vec3(0.34, 0.41, 0.34) * 0.5);
    backHair = smin(backHair, sdEllipsoid(pos - vec3(0.21, 0.02, 0.38), vec3(0.34, 0.41, 0.34) * 0.5), 0.04);
    backHair = smin(backHair, sdEllipsoid(pos - vec3(0.37, 0.1, 0.29), vec3(0.29, 0.39, 0.29) * 0.5), 0.04);
    
    hair = min(hair, backHair);
    
    // the moustache is a torus cut with a cylinder distorted with a sine
    vec3 mSpace = posUntwisted;
    mSpace.y += posUntwisted.x * ps.moustacheBend;
    
    vec3 mPos = (mSpace - vec3(0.0, 0.8, -0.5)).xzy;
    mPos.y *= 3.0;
    
    float mustache = sdTorus(mPos, vec2(0.9, 0.15));
    
    float mCut = length(mSpace.xy - vec2(0.08, 0.12)) - 0.26;
    mCut -= abs(sin(mSpace.x * 25.0)) * 0.03;
    
    mustache = smax(mustache, mCut, 0.06);
    
    // brows are made with an tapered ellipsoid cut with a cylinder
    vec3 browPos = pos;
    
    browPos.y += (pos.x - 0.15) * ps.browBend;
    float brow = sdEllipsoid(browPos - vec3(0.17, 0.42 + ps.browOffset, -0.44 + browPos.x * 0.3), vec3(0.3, 0.3, 0.1) * 0.5);
    float browCut = length(browPos.xy - vec2(0.15, 0.33 + ps.browOffset)) - 0.17;
    
    brow = smax(brow, -browCut, 0.03);
    
    mustache = min(mustache, brow);
    
    // teeth are a cylinder compound
    vec3 tPos = pos - ps.teethPos;
    
    float teeth = length(tPos.xz) - 0.25;
    teeth = abs(teeth) - 0.02;
    teeth = max(teeth, abs(tPos.y) - 0.06);
    
    float eyes = sdEllipsoid(pos - vec3(0.0, 0.25, -0.17), vec3(0.78, 0.74, 0.50) * 0.5);
    

    // Combine all parts together with materil ids
    vec2 res = vec2(head, innerMouth < 0.0 ? INSIDE_MOUTH : SKIN);
    res = combineMin(res, vec2(cap, CAP));
    res = combineMin(res, vec2(visor, CAP2));
    res = combineMin(res, vec2(hair, HAIR));
    res = combineMin(res, vec2(mustache, HAIR2));
    res = combineMin(res, vec2(eyes, EYES));
    res = combineMin(res, vec2(teeth, TEETH));
    return res;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( vec3 pos, MatSpace ps)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e * SDF(pos+0.0005*e, ps).x;
    }
    return normalize(n);
}

// inspired by
// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float shadow(vec3 pos, vec3 lPos, MatSpace ps)
{   
    vec3 dir = lPos - pos;  // Light direction & disantce
    
    float len = length(dir);
    dir /= len;                // It's normalized now
    
    pos += dir * MIN_DST * 2.0;  // Get out of the surface
    
    float dst = SDF(pos, ps).x; // Get the SDF
    
    // Start casting the ray
    float t = 0.0;
    float obscurance = 1.0;
    
    while (t < len)
    {
        if (dst < MIN_DST) return 0.0; 
        obscurance = min(obscurance, (20.0 * dst / t)); 
        t += dst;
        pos += dst * dir;
        dst = SDF(pos, ps).x;
    }
    return obscurance;     
}

float shadow(vec3 p, vec3 n, vec3 lPos, MatSpace ps)
{
    return shadow(p + n * MIN_DST * 40.0, lPos, ps);
}

// Cast a ray across the SDF return x: Distance, y: Materila Id
vec2 castRay(vec3 pos, vec3 dir, float maxDst, float minDst, MatSpace ps)
{
    vec2 dst = vec2(minDst * 2.0, 0.0);
    
    float t = 0.0;
    
    while (dst.x > minDst && t < maxDst)
    {
        dst = SDF(pos, ps);
        t += dst.x;
        pos += dst.x * dir;
    }
    
    return vec2(t + dst.x, dst.y);
}

// A PBR-ish lighting model
vec3 PBRLight(vec3 pos, vec3 normal, vec3 view, PBRMat mat, vec3 lightPos, vec3 lightColor, float fresnel, MatSpace ps, bool shadows)
{
    //Basic lambert shading stuff
    
    //return vec3(fresnel);
    
    vec3 key_Dir = lightPos - pos;
    
    float key_len = length(key_Dir);
    

    
    key_Dir /= key_len;
    

    float key_lambert = max(0.0, dot(normal, key_Dir));
    
     
    float key_shadow = shadows ? S(0.0, 0.10, shadow(pos, normal, lightPos, ps)) : 1.0; 
    
    float diffuseRatio = key_lambert * key_shadow;
   
    
    vec3 key_diffuse = vec3(diffuseRatio);
    

    // The more metalness the more present the Fresnel
    float f = pow(fresnel + 0.5 * mat.metalness, mix(2.5, 0.5, mat.metalness));
    
    // metal specular color is albedo, it is white for dielectrics
    vec3 specColor = mix(vec3(1.0), mat.albedo, mat.metalness);
    
    vec3 col = mat.albedo * key_diffuse * (1.0 - mat.metalness);
    
    // Reflection vector
    vec3 refDir = reflect(view, normal);
    
    // Specular highlight (softer with roughness)
    float key_spec = max(0.0, dot(key_Dir, refDir));
    key_spec = pow(key_spec, 10.0 - 9.0 * mat.roughness) * key_shadow;
    
    float specRatio = mat.metalness * diffuseRatio;
    
    col += vec3(key_spec) * specColor * specRatio;
    col *= lightColor;
    

    
    return col;
}

// Some 3 octave 1D noise for animation
float Noise13(float x, float seed)
{
    float res = Noise1(x, seed);
    res += Noise1(x * 2.0, seed) * 0.5;
    res += Noise1(x * 4.0, seed) * 0.25;
    return res;
}

vec4 render(vec2 uvs)
{
    vec3 col;
    

        
    if (dot(uvs, uvs) > 0.3) // Skip pretty much everything away from the head
    {
           //return vec4(1.0);
    }
    else
    {
        // arrival spin
        float arrival = 1.0 - min(time * 0.5, 1.0);
        arrival *= arrival;

        
        // build camera ray
        vec3 camPos = vec3(0.0, 3.25, -42.0);
        vec3 camDir = vec3(0.0, 0.0,  1.0);
        vec3 rayDir = camDir + vec3(uvs * 0.45, 0.0);

        // mouse interaction
        vec2 mouse = mouse*resolution.xy.xy/resolution.xy;
        if(mouse.x<.001) mouse = vec2(0.5, 0.5);

        vec2 viewAngle = vec2((-mouse.x - 0.45) * pi2, (mouse.y - 0.5) * 0.8);

        MatSpace matSpace;

        // compute two animations
        float slice = time * 0.2;
        float id = floor(slice);
        float progress = fract(slice);

        KeyFrame kf1;
        ExpressionForSeed(kf1, N2(vec2(id, 135.0)));

        KeyFrame kf2;
        ExpressionForSeed(kf2, N2(vec2(id + 1.0, 135.0)));

        // blend them together
        KeyFrame kf;
        mixKeyFrame(kf1, kf2, S(0.8, 1.0, progress), kf);

        // compute the head rotation matrix
        mat4 rotX = rotationX(kf.headRotation.x - arrival * 0.5);
        mat4 rotY = rotationY(kf.headRotation.y  + arrival * (pi * 5.0));
        mat4 rotZ = rotationZ(Noise1(time * 0.2, 345.0) * 0.2);
        mat4 modelMat = rotY * rotX * rotZ;

        // then the viwe matrix
        mat4 viewMat =  rotationY(viewAngle.x) * rotationX(viewAngle.y);
        mat4 modelViewMat = modelMat * viewMat;

        // transform the ray in object space
        camPos = (modelViewMat * vec4(camPos, 1.0)).xyz;
        rayDir = (modelViewMat * vec4(rayDir, 0.0)).xyz;

        // Build matrices & offsets
        buildMatSpace(kf, matSpace);

        
        vec2 d = castRay(camPos, rayDir, MAX_DST, MIN_DST, matSpace);
        
        if (d.x < MAX_DST)
        {
            // if it's a hit render the face
            
            vec3 pos = camPos + rayDir * d.x;
     
            vec3 n;
            
            vec3 normalOffset = vec3(0);
            
            // compute the surface material
            PBRMat mat;
            GetColor(d.y, pos, matSpace, mat, normalOffset);
            
            mat.albedo *= mat.albedo; // Convert albedo to linear space
            
            n = normalize(calcNormal(pos, matSpace) + normalOffset);
            
            // Fake AO
            float ao = SDF(pos + n * 0.7, matSpace).x;
            

            col = mat.albedo * 0.2;
            
            // Fresnel
            float fresnel = 1.0 - sat(dot(n, -rayDir));
    
    
            // transform lights to object space
            vec3 key_LightPos = (modelViewMat * vec4(12.0, 3.0, -30.0, 0.0)).xyz;        
            vec3 fill_LightPos =  (modelViewMat * vec4(-15.0, -7.0, 10.0, 0.0)).xyz;
            
            // Add lighting
            col += PBRLight(pos, n, rayDir, mat, key_LightPos, vec3(1.2), fresnel, matSpace, true);
            col += PBRLight(pos, n, rayDir, mat, fill_LightPos, vec3(3.0), fresnel, matSpace, true);
    
             col *= S(0.0, 0.1, ao) * 0.5 + 0.5; // blend AO to unflatten a bit
            
            col = pow(col,vec3(0.4545)); // gamma correction
            return vec4(col, 0.0);
        }
    }
    
    // Background
 
    vec2 screens = fract(uvs * vec2(2.2, 3.0) + vec2(0.0, 0.5)) - vec2(0.5, 0.5);

    vec2 as = abs(screens);

    float dark = S(0.7, 0.1, as.x) * S(0.7, 0.1, as.y);

    vec3 deepBlue = vec3(0.2, 0.2, 0.8);
    vec3 lightBlue = vec3(0.3, 0.4, 0.9);

    float m = S(-0.1, 0.1, MDist(screens * vec2(6.0, 4.0) - vec2(0, -0.3)));

    float scan = sin(uvs.y * 100.0 + time * 3.0) * 0.1;

    float noiseFrame = floor(time * 20.0);
    float noise = Noise2(uvs * 140.0 + vec2(noiseFrame * 14.3, noiseFrame * 4.3)) * 0.35;

    col = mix(lightBlue, deepBlue, m + scan + noise)  * dark;
  
    return vec4(col, 0.0);
}

// Classic stuff
void main(void)
{ 
    vec2 uv =(gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    vec3 res = render(uv).rgb;

    // Output to screen
    glFragColor = vec4(res.rgb,1.0);
}
