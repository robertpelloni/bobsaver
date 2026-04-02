#version 420

// original https://www.shadertoy.com/view/XcBGRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DISTANCE 10000.0
#define SURFACE_DISTANCE 0.01
#define EPSILON 0.01

const float PI = 3.14159265359;
const float deg2rad = 0.0174532925;

mat2 rot(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 rotatePointUnityEuler(vec3 p, float x, float y, float z){
    p.xz *= rot(deg2rad * y);
    p.zy *= rot(deg2rad * x);    
    p.yx *= rot(deg2rad * z);
    
    return p;
}

float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdSolidAngle(vec3 p, vec2 c, float ra)
{
  // c is the sin/cos of the angle
  vec2 q = vec2( length(p.xz), p.y );
  float l = length(q) - ra;
  float m = length(q - c*clamp(dot(q,c),0.0,ra) );
  return max(l,m*sign(c.y*q.x-c.x*q.y));
}

float sin01(float a)
{
    float b = sin(a*5.0) / 2.0 + 0.5;
    return b*b;
}

float sin02(float a)
{
    float b = sin(a) / 2.0 + 0.5;
    return b*b*b*b*b*b*b;
}

float sin03(float a)
{
    return sin(a) / 2.0 + 0.5;
}

float displacement(vec3 p)
{
    return sin(5.0 * p.x + 4.0*time)*sin(5.0 * p.y + 4.0*time)*sin(5.0 * p.z + 4.0*time);
}

float distanceToScene(vec3 p)
{
    //Main sphere
    vec4 mainSphere = vec4(0.07*sin01(time), -0.07*sin01(time), 0, 0.5 + 0.075*sin01(time));
    float shape1 = sdSphere(p - mainSphere.xyz, mainSphere.w);
    
    //vec3 cylinderRightPos = vec3(0);
    vec3 cylinderRightPos = vec3(0.227, 0.432, 0.099);
    float cylinderRightRadius = 0.1 - 0.015 * sin02((time + PI/4.0 - 0.2)*5.0);
    float cylinderRightHeight = 0.5;
    
    vec3 bp = p - cylinderRightPos;    
    bp = rotatePointUnityEuler(bp, 58.423, 2.507, -22.109);
    
    shape1 = smin(shape1, sdRoundedCylinder(bp, cylinderRightRadius,0.1, cylinderRightHeight), 0.25);
    
    vec3 cylinderSmallPos = vec3(-0.1, 0.831, 0.568);
    float cylinderSmallRadius = 0.075 - 0.01 * sin02((time + PI/4.0 - 0.1)*5.0);
    float cylinderSmallHeight = 0.555;
    
    bp = p - cylinderSmallPos;
    bp = rotatePointUnityEuler(bp, 65.568, -113.973, -41.671);
    
    shape1 = smin(shape1, sdRoundedCylinder(bp, cylinderSmallRadius,0.1, cylinderSmallHeight), 0.1);
    
    vec3 smallSpherePos = vec3(0.25 + 0.075*sin01(time - .03), -0.35 - 0.075*sin01(time - .03), -0.177 -  0.075*sin01(time - .03));
    
    bp = p - smallSpherePos;
    bp = rotatePointUnityEuler(bp, -47.688, 23.452, 43.371);
    
    shape1 = smin(shape1, sdSphere(bp, 0.2  + 0.1*sin01(time - .03)), 0.3);
    
    vec3 anglePos = vec3(-0.108, 0.206, 0.137);
    vec3 anglePos2 = vec3(0.218, 0.186, 0.259);
    
    bp = p - anglePos;
    bp = rotatePointUnityEuler(bp, 10.428, 6.331, 42.379);
    
    shape1 = smin(shape1, sdSolidAngle(bp, vec2(sin(PI/4.0),cos(PI/4.0)), 0.4 - 0.1 * sin02((time + PI/2.0) * 5.0)) -0.1, 0.02);
    
    bp = p - anglePos2;
    bp = rotatePointUnityEuler(bp, -41.338, -20.374, -74.936);
    
    shape1 = smin(shape1, sdSolidAngle(bp, vec2(sin(PI/4.0),cos(PI/4.0)), 0.4 - 0.1 * sin02((time + PI/2.0) * 5.0)) -0.1, 0.02);
    
    vec3 torusPos = vec3(0.228, 0.706, 0.503);
    vec2 torusRadii = vec2(0.38, 0.18);
    
    bp = p - torusPos;
    bp = rotatePointUnityEuler(bp, 22.816, 25.841, -106.461);
    bp.y *= 1.0 - 0.05 * sin02((time + PI/4.0 - 0.15)*5.0);
    bp.z *= 1.0 + 0.1 * sin02((time + PI/4.0 - 0.15)*5.0);
        
    float shape2 = sdTorus(bp, torusRadii);
    
    vec3 valveAPos = vec3(0.22, 1.024, 0.343);
    vec3 valveBPos = vec3(0.317, 1.041, 0.478);
    vec3 valveCPos = vec3(0.386, 0.991, 0.636);
        
    float valveRadius = 0.05;
    float valveHeight = 0.4;
    
    bp = p - valveAPos;
    bp = rotatePointUnityEuler(bp, -25.892, 30.911, -21.724);
    
    shape2 = smin(shape2, max(abs(sdRoundedCylinder(bp, valveRadius, 0.0, valveHeight)) - 0.01, bp.y - 0.3), 0.01);
    
    bp = p - valveBPos;
    bp = rotatePointUnityEuler(bp, -6.346, 25.177, -22.851);
    
    shape2 = smin(shape2, sdRoundedCylinder(bp, valveRadius, 0.0, valveHeight-0.1), 0.01);
    
    bp = p - valveBPos;
    bp = rotatePointUnityEuler(bp, 16.24, 18.123, -27.795);
    
    shape2 = smin(shape2, sdRoundedCylinder(bp, valveRadius, 0.0, valveHeight-0.1), 0.01);
    
    vec3 cylinderLeftPos = vec3(-0.255 + 0.03 * sin02((time + PI/4.0 - 0.2)*5.0), 0.075, 0.273);
    float cylinderLeftRadius = 0.075;
    float cylinderLeftHeight = 0.8;
    bp = p - cylinderLeftPos;
    
    float k = 0.05 * sin02((time + PI/4.0 - 0.2)*5.0);
    float c = cos(k*bp.y);
    float s = sin(k*bp.y);
    mat2 m = mat2(c, -s, s, c);
    vec3 q = vec3(m*bp.xy,bp.z);
    bp = q;
    
    float shape3 = sdRoundedCylinder(bp, cylinderLeftRadius, 0.0, cylinderLeftHeight);
    
    vec3 cylinderLeftSmall1Pos = vec3(-0.308 -0.02 * sin02((time + PI/4.0 - 0.2)*5.0), 1.085, 0.273);
    float cylinderLeftSmall1Radius = 0.075;
    float cylinderLeftSmall1Height = 0.25;
    
    bp = p - cylinderLeftSmall1Pos;
    
    k = -0.3 * sin02((time + PI/4.0 - 0.2)*5.0);
    c = cos(k*bp.y);
    s = sin(k*bp.y);
    m = mat2(c, -s, s, c);
    q = vec3(m*bp.xy,bp.z);
    bp = q;
    
    bp = rotatePointUnityEuler(bp, 0.0, 0.0, 13.068);
    
    shape3 = min(shape3, sdRoundedCylinder(bp, cylinderLeftSmall1Radius,0.0, cylinderLeftSmall1Height));
    
    vec3 cylinderLeftSmall2Pos = vec3(-0.188-0.02 * sin02((time + PI/4.0 - 0.2)*5.0), 1.157, 0.257);
    float cylinderLeftSmall2Radius = 0.075;
    float cylinderLeftSmall2Height = 0.2;
    
    bp = p - cylinderLeftSmall2Pos;
    bp = rotatePointUnityEuler(bp, -25.213, 22.086, -51.354);
    
    shape3 = smin(shape3, max(abs(sdRoundedCylinder(bp, cylinderLeftSmall2Radius,0.0, cylinderLeftSmall2Height)) - 0.02, bp.y - 0.14), 0.01);
    
    float dist = min(shape1, shape2);
    dist = min(dist, shape3);
    
    dist += displacement(p) * 0.01;
    
    return dist;
    
}

const float NOISE_GRANULARITY = 255.0/255.0;
float random(vec2 coords) {
    return fract(sin(dot(coords.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 rayMarch(vec3 ro, vec3 rd, vec2 uv)
{
    float d = 0.0;
    float iter = 0.0;
    for(int i = 0; i < MAX_STEPS && d < MAX_DISTANCE; i++)
    {
        iter += 1.0;
        vec3 p = ro + rd * d;
        float dist = distanceToScene(p);
        d += 0.75 * dist;
        if(dist < SURFACE_DISTANCE)
        {
            
            return vec2(d, iter + (iter/6.0 + 0.5) * dist / SURFACE_DISTANCE);
        }
    }
    return vec2(0.0, iter - d / MAX_DISTANCE + 1.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y;

    vec3 col = vec3(0.0);
    
    vec3 ro = vec3(0, 0.3, -3);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1)); 

    vec2 d = rayMarch(ro, rd, uv);
   
    vec3 gold = vec3(0.8, 0.04, 0.23);
    vec3 lavender = vec3(0.08, 0.45, 1.0);
    
    vec3 myCol = mix(gold, lavender, sin03(time * 2.5));

    col = sin02(time * 5.0) * myCol * d.y * d.x / 75.0 + myCol * d.y / 50.0;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
