#version 420

// original https://www.shadertoy.com/view/ttfyz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ------------------------------------------------------------------------------------
// Original "thinking..." created by kaneta : https://www.shadertoy.com/view/wslSRr
// Original Character By MikkaBouzu : https://twitter.com/mikkabouzu777
// ------------------------------------------------------------------------------------

#define M_HALFPI 1.5707963
#define M_PI 3.1415926
#define M_PI2 M_PI*2.0

#define M_PI03 1.04719
#define M_PI06 2.09439

#define MAT_BLACK 1.0
#define MAT_FACE 2.0
#define MAT_BROW 3.0
#define MAT_CHEEP 4.0
#define MAT_SPHERE 5.0
#define MAT_BG 6.0
#define MAT_CS 7.0

vec3 sinebow(float h) {
    vec3 r = sin((.5-h)*M_PI + vec3(0,M_PI03,M_PI06));
    return r*r;
}

float rand(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 10000.0);
}

float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec3 st)
{
    vec3 ip = floor(st);
    vec3 fp = smoothstep(vec3(0.), vec3(1.), fract(st));
    
    vec4 a = vec4(hash13(ip+vec3(0.)),hash13(ip+vec3(1.,0.,0.)),hash13(ip+vec3(0.,1.,0.)),hash13(ip+vec3(1.,1.,0.)));
    vec4 b = vec4(hash13(ip+vec3(0.,0.,1.)),hash13(ip+vec3(1.,0.,1.)),hash13(ip+vec3(0.,1.,1.)),hash13(ip+vec3(1.,1.,1.)));
    
    a = mix(a, b, fp.z);
    a.xy = mix(a.xy, a.zw, fp.y);
    
    return mix(a.x, a.y, fp.x);
}

mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p );
    return f;
}

float easeInOutQuad(float t) {
    if ((t *= 2.0) < 1.0) {
        return 0.5 * t * t;
    } else {
        return -0.5 * ((t - 1.0) * (t - 3.0) - 1.0);
    }
}

// Distance functions by iq
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
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

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

// Union, Subtraction, SmoothUnion (distance, Material) 
vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 opS( vec2 d1, vec2 d2 )
{ 
    return (-d1.x>d2.x) ? vec2(-d1.x, d1.y): d2;
}

vec2 opSU( vec2 d1, vec2 d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2.x-d1.x)/k, 0.0, 1.0 );
    return vec2(mix( d2.x, d1.x, h ) - k*h*(1.0-h), h > 0.5 ? d1.y : d2.y); }

vec2 opI( vec2 d1, vec2 d2 )
{ 
    //return (d1.x>d2.x) ? d1: vec2(d2.x, d1.y);
    return (d1.x>d2.x) ? d1: d2;
}

// Union, Subtraction, SmoothUnion (distance only)
float opUnion( float d1, float d2 ) {  return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

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

vec3 opTwist(in vec3 p, float k )
{
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xz,p.y);
    return vec3(q.x, q.y, q.z);
}

vec3 TwistY(vec3 p, float power)
{
    float s = sin(power * p.y);
    float c = cos(power * p.y);
    mat3 m = mat3(
          c, 0.0,  -s,
        0.0, 1.0, 0.0,
          s, 0.0,   c
    );
    return m*p;
}

float ease_cubic_out(float p)
{
    float f = (p - 1.0);
    return f * f * f + 1.0;
}

vec3 opRep( in vec3 p, in vec3 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

vec2 opRep2D( in vec2 p, in vec2 c)
{
    return mod(p+0.5*c,c)-0.5*c;
}

// 線分と無限平面の衝突位置算出
// rayPos : レイの開始地点
// rayDir : レイの向き
// planePos : 平面の座標
// planeNormal : 平面の法線
float GetIntersectLength(vec3 rayPos, vec3 rayDir, vec3 planePos, vec3 planeNormal)
{
    return dot(planePos - rayPos, planeNormal) / dot(rayDir, planeNormal);
}

float IsHitSphere(vec3 ro, vec3 rd, vec3 sphereCenter, float radius) {
    vec3 diff = ro - sphereCenter;
    float xc2 = dot(diff, diff);
    float vxc = dot(rd, diff);
    float sq = radius * radius;
    return vxc * vxc - xc2 + sq; 
}

float GetIntersectSphere(vec3 rayPos, vec3 rayDir, vec3 sphereCenter, float radius) {
    float a = length(rayDir);
    float a2 = a * a;
    vec3 diff = rayPos - sphereCenter;
    float b = dot(diff, rayDir);
    float c = length(diff);
    float c2 = c * c - radius * radius;
    float b2ac = sqrt(b * b - a2 * c2);
    float t1 = (-b + b2ac) / a2;
    float t2 = (-b - b2ac) / a2;
    return min(t1, t2);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
// Mikka Boze Distance Function
/////////////////////////////////////////////////////////////////////////////////////////////////
#define RAD90 (M_PI * 0.5)

float sdEar(vec3 p, float flip, float sc)
{
    p.x *= flip;
    p = rotate(p, RAD90+0.25, vec3(0,0,1));    
    return sdCappedTorus(p + vec3(0.05, 0.175, 0) * sc, vec2(sin(0.7),cos(0.7)), 0.03 * sc, 0.01 * sc);
}

#define EYE_SPACE 0.04

vec3 opBendXY(vec3 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xy,p.z);
}

float sdMouse(vec3 p, float sc, float ms)
{
    vec3 q = opBendXY(p, 2.0);
    
    //return sdEllipsoid(q - vec3(0,0,0.2) * sc, vec3(0.05,0.015 + sin(time * 1.) * 0.05,0.05) * sc);
    return sdEllipsoid(q - vec3(0,0,0.2) * sc, vec3(0.05,0.02 * ms,0.2 * ms) * sc);
}

float sdCheep(vec3 p, float flip, float sc)
{
    p.x *= flip;
    
    float x = 0.05;
    float z = -0.18;
    p = rotate(p, M_PI * -0.6 * (p.x - x) / sc, vec3(0,1,0));

    float d = sdCapsule(opBendXY(p + vec3(x, -0.01, z) * sc, 100.0/sc), vec3(-0.005,0.0,0) * sc, vec3(0.005, 0., 0) * sc, 0.0025 * sc);
    float d1 = sdCapsule(opBendXY(p + vec3(x+0.01, -0.01, z) * sc, 200.0/sc), vec3(-0.0026,0.0,0) * sc, vec3(0.0026, 0., 0) * sc, 0.0025 * sc);
    float d2 = sdCapsule(opBendXY(p + vec3(x+0.019, -0.015, z) * sc, -100.0/sc), vec3(-0.01,0.0,-0.01) * sc, vec3(0.0045, 0., 0.0) * sc, 0.0025 * sc);
    
    return opUnion(opUnion(d, d1), d2);
}

float sdEyeBrow(vec3 p, float flip, float sc)
{
    p.x *= flip;
    
    p = rotate(p, M_PI * -0.0225, vec3(0,0,1));
    
    return sdRoundBox(p + vec3(0.03, -0.14,-0.125) * sc, vec3(0.015,0.0025,0.1) * sc, 0.0001);
}

vec2 sdBoze(vec3 p, float sc, float ms)
{    
    vec2 result = vec2(0.);
    
    // head
    float d = sdCapsule(p, vec3(0,0.05,0) * sc, vec3(0, 0.11, 0) * sc, 0.125 * sc);
    
    float d1 = sdRoundedCylinder(p + vec3(0,0.025,0) * sc, 0.095 * sc, 0.05 * sc, 0.0);
    
    d = opSmoothUnion(d, d1, 0.1 * sc);
    
    // ear
    float d2 = sdEar(p, 1.0, sc);
    d = opUnion(d, d2);
    float d3 = sdEar(p, -1.0, sc);
    d = opUnion(d, d3);

    vec2 head = vec2(d, MAT_FACE);

    // eye
    float d4 = sdCapsule(p, vec3(EYE_SPACE, 0.06, 0.125) * sc, vec3( EYE_SPACE, 0.08, 0.125) * sc, 0.0175 * sc);
    float d5 = sdCapsule(p, vec3(-EYE_SPACE,0.06, 0.125) * sc, vec3(-EYE_SPACE, 0.08, 0.125) * sc, 0.0175 * sc);
    vec2 eye = vec2(opUnion(d4, d5), MAT_BLACK);
    
    // mouse
    float d6 = sdMouse(p, sc, ms);
    vec2 mouse = vec2(d6, MAT_BROW);
    
    // cheep
    float d7 = sdCheep(p, 1.0, sc);
    float d8 = sdCheep(p, -1.0, sc);
    vec2 cheep = vec2(opUnion(d7, d8), MAT_CHEEP);

    // eyebrows
    float d9 = sdEyeBrow(p, 1.0, sc);
    float d10 = sdEyeBrow(p, -1.0, sc);
    eye.x = opUnion(eye.x, opUnion(d9, d10));
    
    mouse = opU(eye, mouse);
    result = opS(mouse, head);
    result = opU(cheep, result);
    
    
    return result;
}
/////////////////////////////////////////////////////////////////////////////////////////////////
// End of Mikka Boze
/////////////////////////////////////////////////////////////////////////////////////////////////

float densitycalc(vec3 p){
    p = rotate(p, 0.45, vec3(0,0,1));
    vec2 r = sdBoze(p, 5.0, (sin(time * 0.2) * 0.5 + 0.5)*1.5);
    return fbm(p * 10. + time * 0.2) - min(r.x, 1.) * 10.;
}

#define MAX_MARCH 32
#define MAX_MARCH_L 6

vec3 raycast(vec3 p, vec3 ray, float depth)
{
    vec3 result = vec3(0.);
        
    //vec3 spherePos = vec3(0.,0.2 + sin(time * 4.0) * 0.5,0.);
    vec3 spherePos = vec3(-0.05,0.2,0.);
    float time = time * 2.2;
    
    float radius = 1.5;
    float d = GetIntersectSphere(p, ray, spherePos, radius);
    
    if((d > 0.)&&(d < depth)){
        float step = 1.0 / float(MAX_MARCH);
        float lightStep = 1.0 / float(MAX_MARCH_L);

        vec3 qq = rotate(p, 0.45, vec3(0,0,1));
        vec2 r = sdBoze(qq, 5.0, 1.0);
        
        vec3 ro2 = p + ray * (r.x - step);
        float t = hash13(ro2 * 100.) * 0.01;
        float alpha = 0.;
        float transmittance = 1.0;
        float absorption   = 45.;
        //vec3 sunDir = normalize(vec3(cos(time),1,sin(time)));
        vec3 sunDir = normalize(vec3(-1,1,-0.25));
        vec3 col = vec3(0.5);
        
        for(int i = 0; i < MAX_MARCH; i++){
            t += step;
            vec3 pp = ro2 + ray * t;
            if((length(pp - spherePos) > radius)||((d + t) >= depth))
                break;
            vec3 q = pp - spherePos - vec3(0.,0.1 ,0.);
            
            float density = densitycalc(q);
            
            if(density > 0.){
                float dd = density * step;
                transmittance *= 1.0 - dd * absorption;
                if(transmittance < 0.01)
                    break;
                alpha += 100. * dd * transmittance;
                
                float transmittanceLight = 1.0;
                vec3 lightPos = q;
                
                for(int j = 0; j < MAX_MARCH_L; j++){
                    float densityLight = densitycalc(q + sunDir * float(j) * lightStep);
                    if(densityLight > 0.0){
                        float dl = densityLight * lightStep;
                        transmittanceLight *= 1.0 - dl * absorption * 0.1;
                        if(transmittanceLight < 0.01){
                            transmittanceLight = 0.;
                            break;
                        }
                    }
                }
                col += vec3(1.,.7,.5) * (150. * dd * transmittance * transmittanceLight);
            }
        }
        result = col * alpha;
    }
    
    return result;
}

mat3 camera(vec3 ro, vec3 ta, float cr )
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

float luminance(vec3 col)
{
    return dot(vec3(0.298912, 0.586611, 0.114478), col);
}

vec3 reinhard(vec3 col, float exposure, float white) {
    col *= exposure;
    white *= exposure;
    float lum = luminance(col);
    return (col * (lum / (white * white) + 1.0) / (lum + 1.0));
}

void main(void)
{
    
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    float time = time * 0.5;
    float y = 0.5;
    vec3 ro = vec3(0., y, 5.);
    vec3 ta = vec3(0., y, 0.);
    mat3 c = camera(ro, ta, 0.);
    vec3 ray = c * normalize(vec3(p, 3.5));
    vec3 col = vec3(0.05,0.2,0.7);
    
    col += raycast(ro, ray, 100.);
        
    col = reinhard(col.xyz, 2.9, 100.0);
    col = pow(col.xyz, vec3(1.0/0.9));
    
    glFragColor = vec4(col,1.0);
}
