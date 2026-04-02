#version 420

// original https://www.shadertoy.com/view/Ndj3WD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

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
#define M_PI2 M_PI*2.0
#define RAD90 (M_PI * 0.5)

struct surface {
    float dist;
    vec4 albedo;
    float specular;
    int count;
    bool isHit;
};

// Surface Data Define
#define SURF_NOHIT(d)   (surface(d, vec4(0),              0.0, 0, false))
#define SURF_BLACK(d)     (surface(d, vec4(0,0,0,1),       0.001, 0, true))
#define SURF_FACE(d)     (surface(d, vec4(1,0.7,0.6,1),     0.00001, 0, true))
#define SURF_MOUSE(d)     (surface(d, vec4(1,0,0.1,1),       0.0, 0, true))
#define SURF_CHEEP(d)     (surface(d, vec4(1,0.3,0.4,1),     0.02, 0, true))
#define SURF_SPHERE(d)     (surface(d, vec4(0.1,0.1,0.1,1),0.9, 0, true))
    
#define AA 1

#define M_PI03 1.04719
#define M_PI06 2.09439
vec3 sinebow(float h) {
    vec3 r = sin((.5-h)*M_PI + vec3(0,M_PI03,M_PI06));
    return r*r;
}

// easing function
float QuadraticEaseOut(float p)
{
    return -(p * (p - 2.));
}

float QuadraticEaseInOut(float p)
{
    if(p < 0.5)
    {
        return 2. * p * p;
    }
    else
    {
        return (-2. * p * p) + (4. * p) - 1.;
    }
}

float CubicEaseIn(float p)
{
    return p * p * p;
}

float CubicEaseInOut(float p)
{
    if(p < 0.5)
    {
        return 4. * p * p * p;
    }
    else
    {
        float f = ((2. * p) - 2.);
        return 0.5 * f * f * f + 1.;
    }
}

float QuarticEaseOut(float p)
{
    float f = (p - 1.);
    return f * f * f * (1. - p) + 1.;
}

float BackEaseIn(float p)
{
    return p * p * p - p * sin(p * M_PI);
}

// random
//float rand3d(vec3 st)
//{
//    return fract(sin(dot(st.xyz, vec3(12.9898, 78.233, 56.787))) * 10000.0);
//}
//  1 out, 3 in...
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
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
    float sp = mix(d2.specular, d1.specular, h);
    return surface(d, albedo, sp, d1.count, true);
}

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

surface opLerp(surface d1, surface d2, float t) {
    surface d;
    d.dist = mix(d1.dist, d2.dist, t);
    d.albedo = mix(d1.albedo, d2.albedo, t);
    d.specular = mix(d1.specular, d2.specular, t);
    d.count = int(mix(float(d1.count), float(d2.count), t));
    d.isHit = t > 0.5 ? d1.isHit : d2.isHit;
    return d;
}

//https://www.shadertoy.com/view/NdS3Dh
//SmoothSymmetricPolarMod aka smoothRot
//
//s repetitions
//m smoothness (0-1)
//c correction (0-1)
//d object displace from center
//
vec2 smoothRot(vec2 p,float s,float m,float c,float d){
  s*=0.5;
  float k=length(p);
  float x=asin(sin(atan(p.x,p.y)*s)*(1.0-m))*k;
  float ds=k*s;
  float y=mix(ds,2.0*ds-sqrt(x*x+ds*ds),c);
  return vec2(x/s,y/s-d);
}

//Rotation
vec2 rot(vec2 p,float f){
    float s=sin(f);float c=cos(f);
    return p*mat2(c,-s,s,c);
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

// 球体
#define SEQ_0 (1.5)
// モーフィング坊主
#define SEQ_1 (SEQ_0 + 0.5)
// ねじれ坊主
#define SEQ_2 (SEQ_1 + 3.0)
// 分裂坊主
#define SEQ_3 (SEQ_2 + 5.0)
// ズームエンド
#define SEQ_4 (SEQ_3 + 3.)

#define SEQ_0_D(t) (t / SEQ_0)
#define SEQ_1_D(t) ((t - SEQ_0) / (SEQ_1 - SEQ_0))
#define SEQ_2_D(t) ((t - SEQ_1) / (SEQ_2 - SEQ_1))
#define SEQ_3_D(t) ((t - SEQ_2) / (SEQ_3 - SEQ_2))
#define SEQ_4_D(t) ((t - SEQ_3) / (SEQ_4 - SEQ_3))

#define LOOP (mod(time, SEQ_4+0.1))

int getSeq(){
    float t = LOOP;
    //float t = time;
    
    if(t < SEQ_0){
        return 0;
    }else if(t < SEQ_1){
        return 1;
    } else if(t < SEQ_2){
        return 2;
    } else if(t < SEQ_3){
        return 3;
    }
    //else if(t < SEQ_4){
        return 4;
    //} 
    
    return 0;
}

surface bioBoze(vec3 p, float t)
{
    surface result = SURF_NOHIT(1e5);
    
    float ms = sin(time*3.0) * 0.5 + 0.75;

    float t2 = t * 5.32;
    float repetitions=6.0;
    float smoothness=0.0125;
    float correction=0.0;
    float displace=t*0.1;
    
    float s = 1.0;
    for(int i = 0; i < 3; i++)
    {
        p.yz=rot(p.yz,-cos(t2*1.3+time*0.1)*0.378 * (1.0-t));
        p.xy=smoothRot(p.xy,repetitions,smoothness,correction,displace);
        p.xz=rot(p.xz,sin(-t2*0.25+RAD90)*0.362*t2);

        // boze
        surface boze = sdBoze(p, vec3(s), ms);
        s *= 0.78;
        p.y -= 0.5*s*t;
        p.xz-=0.175*s*t;

        result = opSU(result, boze, smoothness);
    }
    return result;
}

surface map(vec3 p)
{
    surface result = SURF_NOHIT(1e5);
     float ti = LOOP;
    int seq = getSeq();
    if(seq == 0) {
        vec3 bp = vec3(0, -1.75 + QuarticEaseOut(SEQ_0_D(ti)) * 1.75, 0);
        // 球体
        result = SURF_SPHERE(sdCapsule(p + bp, vec3(0,0.0,0), vec3(0, 0., 0), 0.125));
     } else if(seq == 1) {
        // モーフィング坊主
        float t = QuadraticEaseInOut(saturate(SEQ_1_D(ti)));
        result = SURF_SPHERE(sdCapsule(p, vec3(0,0.0,0), vec3(0, 0., 0), 0.125));
        surface boze = sdBoze(p, vec3(1), 1.0);

        result = opLerp(result, boze, t);
        
    } else if(seq == 2) {
        // ねじれ坊主
        float d = saturate(SEQ_2_D(ti));
        float t = QuadraticEaseInOut(d);
        p = TwistY(p, sin(d * M_PI2) * 5.);
        float s = noise(normalize(-p)*2.0+vec3(0,ti*(t*1.5+2.0),0)) * 0.5 * t + 1.0;
        
        result = sdBoze(p, vec3(s), 1.0);
    } else if(seq == 3) {        
         // 通常のBoze
        float s2 = noise(normalize(-p)*2.0+vec3(0,ti*3.5,0)) * 0.5 + 1.0;
        surface b2 = sdBoze(p, vec3(s2), 1.0);
        
        float t = QuarticEaseOut(SEQ_3_D(ti));
        float t2 = t * 5.32;

        // 分裂坊主と合成        
        result = opLerp(b2, bioBoze(p, t), saturate(t2));
    } else if(seq == 4) {
        // ズームエンド
        float t = BackEaseIn(SEQ_4_D(ti));
        float t2 = QuadraticEaseInOut(SEQ_4_D(ti));
        p.z -= t;
        //p.z -= t2*0.5;
        p.y -= t2*0.2;
        result = bioBoze(p, 1.0);
    }
    
    
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
        d = hit.dist * 0.5;
        
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

    vec3 sky = sinebow(fbm(vec3(ray+time*0.2))*5.5)*0.5+0.25;
    if(mat.isHit)
    {
        // Lighting
        vec3 normal = norm(pos);

        vec3 lightDir = normalize(vec3(0.5, 1, 1));
        vec3 lightColor = vec3(1.);
        
        vec3 halfLE = normalize(lightDir - ray);
        float NoL = saturate(pow(dot(normal, lightDir)*0.5+0.5,2.0));
        
        float spec = pow(clamp(dot(normal, halfLE), 0.0, 1.0), (1.-mat.specular)*500.);
            
        vec3 ref = reflect(ray, normal);
        
        vec3 ambientColor = sinebow(fbm(vec3(ref + time*0.2))*5.5)*0.05;
        
        mat.albedo.rgb *= NoL * lightColor;
        mat.albedo.rgb +=  ambientColor + spec*lightColor;
    }
    
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

void main(void)
{
    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
#else
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif
    
        vec3 ro = vec3(0, 0.2, 1.0);
        //vec3 ro = vec3(cos(time)*2.5, 0.0, sin(time)*2.5);
        vec3 ta = vec3(0, 0.05, 0);

        mat3 c = camera(ro, ta, 0.0);
        vec3 ray = c * normalize(vec3(p, 1.5));
        vec3 col = render(ro, ray, gl_FragCoord.xy);
    
        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif
    glFragColor = vec4(tot,1.0);
}
