#version 420

// original https://www.shadertoy.com/view/3s2fWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ------------------------------------------------------------------------------------
// Original "thinking..." created by kaneta : https://www.shadertoy.com/view/wslSRr
// Original Character By MikkaBouzu : https://twitter.com/mikkabouzu777
// ------------------------------------------------------------------------------------

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

vec3 sinebow(float h) {
    vec3 r = sin((.5-h)*M_PI + vec3(0,M_PI03,M_PI06));
    return r*r;
}

float rand(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 10000.0);
}

float rand3d(vec3 st)
{
    return fract(sin(dot(st.xyz, vec3(12.9898, 78.233, 56.787))) * 10000.0);
}

float noise(vec3 st)
{
    vec3 ip = floor(st);
    vec3 fp = smoothstep(vec3(0.), vec3(1.), fract(st));
    
    vec4 a = vec4(rand3d(ip+vec3(0.)),rand3d(ip+vec3(1.,0.,0.)),rand3d(ip+vec3(0.,1.,0.)),rand3d(ip+vec3(1.,1.,0.)));
    vec4 b = vec4(rand3d(ip+vec3(0.,0.,1.)),rand3d(ip+vec3(1.,0.,1.)),rand3d(ip+vec3(0.,1.,1.)),rand3d(ip+vec3(1.,1.,1.)));
    
    a = mix(a, b, fp.z);
    a.xy = mix(a.xy, a.zw, fp.y);
    
    return mix(a.x, a.y, fp.x);
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

vec2 map(vec3 p)
{
    vec2 result = vec2(1.);
    
    //vec4 v = voronoi(p * 0.25);
    
    //float s = 1.0;
    //p = deform( p, time, s );
    
    for(float i = 0.; i < 4.; i++){
        float time = time * 0.2 + i * 0.25;
        float sc = fract(time);

        vec3 q = p;
        //vec3 q = p - vec3(0.,0.,-1. + mod(time, 2.0));
        //q.x = mod(p.x+1.0,2.0)-1.0;
        //q.z = mod(p.z+1.0,2.0)-1.0;
        //q.xz = opRep2D(q.xz, vec2(1.0));
        //q = opRep(q, vec3(1.0));
        //q.x += cos(time + pow(1.0-q.y, 25.))*0.1;

        //q.xyz = v.yzw;
        //vec3 q2 = q;
        //vec3 index = floor(p + 0.5);
        //float angle = (index.y + index.x + time * 2.5) * M_PI2;

        //q.xy += vec2(cos(angle)*0.075, sin(angle)*0.05);
        //q = rotate(q, time * 15., vec3(0,0,1));
        q = rotate(q, sc * 8. - time * 0.5, vec3(0,0,1));
        
        //q.y -= mod(rand(index.xy) * 10. + timeSpeed * (0.5 + rand(index.yx) * 2.5), 10.) - 5.;

        //q = rotate(q, angle, normalize(vec3(noise(vec3(index.xy, timeSpeed)), noise(vec3(index.y, timeSpeed, index.z)), noise(vec3(timeSpeed, index.zx)))));

        result = opU(sdBoze(q, pow(sc,6.0) * 20., 0.0 + (1. - pow(1. - smoothstep(0.3,0.99, sc),1.5)) * 2.), result);
    }
    
    //vec2 body = vec2(sdEllipsoid(q2 + vec3(0.,0.2,0.025), vec3(0.2, 0.175, 0.15)), MAT_FACE);
    //result = opSU(body, result, 0.025);
    
    // background
    //vec2 bg1 = vec2(sdPlane(p + vec3(0., 1.0, 0.), vec4(0,1,0,0)), MAT_BG);
    //vec2 bg2 = vec2(sdPlane(p - vec3(0., 1.0, 0.), vec4(0,-1,0,0)), MAT_BG);
    
    //result = opSU(bg1, result,  0.25);
    //result = opSU(bg2, result,  0.25);
    
    //result.x *= s;
    
    return result;
}

vec3 norm(vec3 p)
{
    vec2 e=vec2(.001,.0);
    return normalize(.000001+map(p).x-vec3(map(p-e.xyy).x,map(p-e.yxy).x,map(p-e.yyx).x));
}

vec3 fresnelSchlick_roughness(vec3 F0, float cosTheta, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

// Unreal Engine Ambient BRDF Approx
// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile?lang=en-US
vec3 EnvBRDFApprox( vec3 SpecularColor, float Roughness, float NoV )
{
    const vec4 c0 = vec4( -1, -0.0275, -0.572, 0.022 );
    const vec4 c1 = vec4( 1, 0.0425, 1.04, -0.04 );
    vec4 r = Roughness * c0 + c1;
    float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
    vec2 AB = vec2( -1.04, 1.04 ) * a004 + r.zw;
    return SpecularColor * AB.x + AB.y;
}

vec3 calcAmbient(vec3 pos, vec3 albedo, float metalness, float roughness, vec3 N, vec3 V, float t)
{
    vec3 F0 = mix(vec3(0.04), albedo, metalness);
    vec3 F  = fresnelSchlick_roughness(F0, max(0.0, dot(N, V)), roughness);
    vec3 kd = mix(vec3(1.0) - F, vec3(0.0), metalness);
    
    float aoRange = t/20.0;
    float occlusion = max( 0.0, 1.0 - map( pos + N*aoRange ).x/aoRange );
    occlusion = min(exp2( -.8 * pow(occlusion, 2.0) ), 1.0);
    
    vec3 ambientColor = vec3(0.5);
    
    vec3 diffuseAmbient = kd * albedo * ambientColor * min(1.0, 0.75+0.5*N.y) * 3.0;
    vec3 R = reflect(-V, N);
    
    vec3 col = mix(vec3(0.5) * pow( 1.0-max(-R.y,0.0), 4.0), ambientColor, pow(roughness, 0.5));
    vec3 ref = EnvBRDFApprox(F0, roughness, max(dot(N, V), 0.0));
    vec3 specularAmbient = col * ref;

    diffuseAmbient *= occlusion;
    return vec3(diffuseAmbient + specularAmbient);
}

///////////////////////////////////////////////////////////////////////
#define MAX_MARCH 100

vec3 materialize(vec3 p, vec3 ray, float depth, vec2 mat)
{
    vec3 col = vec3(0.12, 0., 0.4);
    //vec3 col = min(vec3(0.12, 0., 0.4) + sinebow(fract(time * 1.5)) * vec3(0.1), 1.);
    vec3 nor = norm(p);
    vec3 sky = vec3(1.0,0.0,0.0);
    //vec3 sky = min(sinebow(fract(time * 2.5 + 0.5)) * vec3(0.35) + vec3(0.3) + pow(max(1.29 - p.y, 0.), 5.), 1.);
    //if(p.y >= 0.29) 
    if(depth > 100.)
    {
        col = sky;
    } else {
        if(mat.y > 0.0){
            vec2 index = floor(p.xz + 0.5);

            float roughness, metalness;
            if(mat.y == MAT_BLACK) {
                col = vec3(0.0, 0.0, 0.0);
                roughness = 0.8;
                metalness = 0.0;
            } else if(mat.y == MAT_FACE) {
                col = vec3(1.0, 0.8, 0.6);
                roughness = 0.8;
                metalness = 0.0;
            } else if(mat.y == MAT_BROW) {
                col = vec3(1.0, 0, 0);
                roughness = 0.1;
                metalness = 0.0;
            } else if(mat.y == MAT_CHEEP) {
                col = vec3(1.0, 0.3, 0.5);
                roughness = 0.1;
                metalness = 0.0;
            } else if(mat.y == MAT_BG) {
                //col = min(sinebow(fract((index.x + index.y) * 0.175 + time * 0.5 + 0.5)) * vec3(0.3), 1.);
                //float e = smoothstep(abs(mod(p.y + 0.25 + time * 0.5, 0.5) - 0.25), 0.0, 0.0125); 
                roughness = 1.0;
                metalness = 0.0;
            }

            vec3 result = vec3(0.);
            result += calcAmbient(p, col, metalness, roughness, nor, -ray, depth);
            col = result;
        }
        //float fog = min(1.0, (1.0 / float(MAX_MARCH)) * float(mat.x))*5.0;
        //vec3  fog2 = vec3(0.015,0.015,0.01) * depth;
        //col += vec3(0.01, 0.01, 0.05) * fog;
        //col += fog2 + sky * 0.1;
        //col -= fog2;
    }
    
    return col;
}

vec3 trace(vec3 p, vec3 ray)
{
    float t = 0.0;
    vec3 pos;
    vec2 mat;
    
    //float planeDistance = GetIntersectLength(p, ray, vec3(0.,0.3,0.), vec3(0.,1.,0.));
    //t = planeDistance;
    
    int count = 0;
    for (int i = 0; i < MAX_MARCH; i++) {
        pos = p + ray * t;
        mat = map(pos);
        if (mat.x <= 0.0001) {
            break;
        }
        t += mat.x * 0.5;
        count++;
    }
    
    p = p + t * ray;
    mat.x = float(count);
    return materialize(p, ray, t, mat);
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
    
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    float time = time * 1.5;
    //float x = mod(time * 0.5, 10000.);
    //vec3 ro = vec3(cos(rotSpeed)*5.0, 0., sin(rotSpeed)*5.0);
    //vec3 ta = vec3(0., 0.0, 0.);
    //vec3 ro = vec3(x, 0., 5.5);
    //vec3 ta = vec3(x, 0., 0.);
    vec3 ro = vec3(sin(time * 2.3) * 0.1, cos(time * 3.23) * 0.1, 1.0);
    vec3 ta = vec3(-cos(time * 0.9) * 0.05, sin(time * 0.3) * 0.05 , 0.);
    //vec3 ta = ro + vec3(cos(rotSpeed)*5.0, 0., sin(rotSpeed)*5.0);
    mat3 c = camera(ro, ta, 0.);
    vec3 ray = c * normalize(vec3(p, 3.5));
    vec3 col = trace(ro, ray);
    
    glFragColor = vec4(col,1.0);
}
