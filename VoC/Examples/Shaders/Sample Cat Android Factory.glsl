#version 420

// original https://www.shadertoy.com/view/sts3DB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Adapted from original shader: https://www.shadertoy.com/view/ldcyW4
// modeled by https://joetech.itch.io/sdf-editor
const float epsilon = 0.01;
const float pi = 3.14159265359;
const float halfpi = 1.57079632679;
const float twopi = 6.28318530718;

mat3 rotateMat(vec3 p, float angle, vec3 axis){
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
    return m;
}

#define LIGHT normalize(vec3(1.0, 1.0, 0.0))

float displacement(vec3 p){
    return sin(20.141592*p.x)*sin(0.141592*p.y)*sin(20.131592*p.y);
}

//----------------------------------------------------------------------------------
//  from SDF Editor
//----------------------------------------------------------------------------------
float pSphere(float r, vec3 p)
{
     return length(p) - r;
}

// bound
float pTriPrism(float h, float r, vec3 p)
{
    vec3 q = abs(p);
    return max(q.z-h,max(q.x*0.866025+p.y*0.5,-p.y)-r*0.5);
}

float pCapsule(float r, float h, vec3 p)
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

float pRoundCone(float r1, float r2, float h, vec3 p)
{
    vec2 q = vec2( length(p.xz), p.y );

    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0 ) return length(q) - r1;
    if( k > a*h ) return length(q-vec2(0.0,h)) - r2;

    return dot(q, vec2(a,b) ) - r1;
}

// bound
float pEllipsoid(vec3 r, vec3 p)
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

vec3 mTranslation(vec3 inv_translation, vec3 p)
{
    return p + inv_translation;
}

vec3 mRotation(mat3 inv_rotation, vec3 p)
{
    return inv_rotation * p;
}

vec3 mMirror(vec3 normal, float dist, vec3 p)
{
    float d = max(0.0, dot(normal, p) - dist);
    return p - 2.0 * d * normal;
}

vec3 mRepInf(vec3 cell_size, vec3 p)
{
    vec3 inv_cell_size = vec3(greaterThan(cell_size, vec3(0.0))) * 1.0 / cell_size;
    return p - cell_size * round(p * inv_cell_size);
}

vec3 mRepLim(vec3 cell_size, vec3 grid_size, vec3 p)
{
    return p - cell_size * clamp(round(p / cell_size), -grid_size, grid_size);
}

vec3 mElongation(vec3 elongation, vec3 p)
{
    return p - clamp(p, -elongation, elongation);
}

float oUnion(float d1, float d2)
{
    return min(d1, d2);
}

float oSubtraction(float d1, float d2)
{
    return max(d1, -d2);
}

float oIntersection(float d1, float d2)
{
    return max(d1, d2);
}

float oOnion(float thickness, float d)
{
    return abs(d) - thickness;
}

float oThicken(float thickness, float d)
{
    return d - thickness;
}

float oSmoothUnion(float k, float d1, float d2)
{
    float h = clamp(0.5 + 0.5*(d1 - d2) / k, 0.0, 1.0);
    return mix(d1, d2, h) - k*h*(1.0-h);
}

float oSmoothSubtraction(float k, float d1, float d2)
{
    float h = clamp(0.5 - 0.5*(d1 + d2) / k, 0.0, 1.0);
    return mix(d1, -d2, h) + k*h*(1.0-h);
}

float oSmoothIntersection(float k, float d1, float d2)
{
    float h = clamp(0.5 - 0.5*(d1 - d2) / k, 0.0, 1.0);
    return mix(d1, d2, h) + k*h*(1.0-h);
}
//-----------------------------------------------------------------
//for sdf function
mat3 RoIn_1 = mat3(1, -0, 0, 0, 1, -0, 0, 0, 1);
vec3 ReCe_2 = vec3( 3, -1, 3 );
mat3 RoIn_3 = mat3(1, -0, 0, 0, 1, -0, 0, 0, 1);
vec3 TrIn_4 = vec3( 0, -0.74, 0 );
vec3 ElRa_5 = vec3( 1.2, 0.05, 0.1 );
vec3 TrIn_6 = vec3( 0, 0.2, 0 );
float CaRa_7 = 0.07;
float CaHe_8 = 1.;
vec3 MiNo_9 = vec3( 1, 0, 0 );
float MiDi_10 = 0.06;
vec3 TrIn_11 = vec3( 0.17, 0.1, -0.52 );
float SpRa_12 = 0.15;
vec3 MiNo_13 = vec3( 1, 0, 0 );
float MiDi_14 = 0.06;
vec3 TrIn_15 = vec3( 0.17, 0.1, -0.52 );
float SpRa_16 = 0.2;
vec3 TrIn_17 = vec3( 0, 3, 0 );
float RoRa_18 = 1.2;
float RoRa_19 = 0.5;
float RoHe_20 = 1.;
vec3 MiNo_21 = vec3( 1, 0, 0 );
float MiDi_22 = 0.;
vec3 TrIn_23 = vec3( 0.5, 0.09, 0 );
mat3 RoIn_24 = mat3(0.925417, -0.163176, 0.34202, 0.044233, 0.942887, 0.330162, -0.376361, -0.290409, 0.879781);
float TrHe_25 = 0.02;
float TrRa_26 = 0.41;
vec3 TrIn_27 = vec3( 0, 0.84, 0 );
mat3 RoIn_28 = mat3(1, -0, 0, 0, -1, -0, 0, 0, -1);
float RoRa_29 = 1.;
float RoRa_30 = 0.5;
float RoHe_31 = 1.;

float sdf(vec3 p0)
{
    float d1;
    float d2;
    float d3;
    float d4;
    float d5;
    float d6;
    float d7;

    {
        vec3 p1 = mRotation(RoIn_1, p0);
    }
    {
        vec3 p1 = mRepInf(ReCe_2, p0);
        {

            mat3 mt = rotateMat(p1,time,vec3(0.,1.,0.));
            //vec3 p2 = mRotation(RoIn_3, p1);
            vec3 p2 = mRotation(mt, p1);
            {
                vec3 p3 = mTranslation(TrIn_4, p2);
                d1 = pEllipsoid(ElRa_5, p3);
            }
        }
        {
            vec3 p2 = mTranslation(TrIn_6, p1);
            d2 = pCapsule(CaRa_7, CaHe_8, p2);
        }
        {
            vec3 p2 = mMirror(MiNo_9, MiDi_10, p1);
            {
                vec3 p3 = mTranslation(TrIn_11, p2);
                d3 = pSphere(SpRa_12, p3);
            }
        }
        {
            vec3 p2 = mMirror(MiNo_13, MiDi_14, p1);
            {
                vec3 p3 = mTranslation(TrIn_15, p2);
                d4 = pSphere(SpRa_16, p3);
            }
        }
        {
            vec3 p2 = mTranslation(TrIn_17, p1);
            d5 = pRoundCone(RoRa_18, RoRa_19, RoHe_20, p2);
        }
        {
            vec3 p2 = mMirror(MiNo_21, MiDi_22, p1);
            {
                vec3 p3 = mTranslation(TrIn_23, p2);
                {
                    vec3 p4 = mRotation(RoIn_24, p3);
                    d6 = pTriPrism(TrHe_25, TrRa_26, p4);
                }
            }
        }
        {
            vec3 p2 = mTranslation(TrIn_27, p1);
            {
                vec3 p3 = mRotation(RoIn_28, p2);
                d7 = pRoundCone(RoRa_29, RoRa_30, RoHe_31, p3);
            }
        }
    }
    return oUnion(d6, oUnion(d5, oUnion(oSubtraction(d7, d4), oUnion(d3, oUnion(d2, d1)))));
}

vec3 RayMarch(vec3 rayDir, vec3 cameraOrigin)
{
    const int maxItter = 128;
    //const float maxDist = 30.0;
    const float maxDist = 130.0;
    
    float totalDist = 0.0;
    vec3 pos = cameraOrigin;
    float dist = epsilon;
    float itter = 0.0;
    
    for(int i = 0; i < maxItter; i++)
    {
        dist = sdf(pos);
        itter += 1.0;
        totalDist += dist; 
        pos += dist * rayDir;
        
        if(dist < epsilon || totalDist > maxDist)
        {
            break;
        }
    }
    
    return vec3(dist, totalDist, itter/128.0);
}

float AO(vec3 pos, vec3 n)
{
    float res = 0.0;
    vec3 aopos = pos;
    
    for( int i=0; i<3; i++ )
    {   
        aopos = pos + n*0.2*float(i);
        float d = sdf(aopos);
        res += d;
    }

    return clamp(res, 0.0, 1.0);   
}

//Camera Function by iq :
//https://www.shadertoy.com/view/Xds3zN
mat3 SetCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//Normal and Curvature Function by Nimitz;
//https://www.shadertoy.com/view/Xts3WM
vec4 NorCurv(in vec3 p)
{
    vec2 e = vec2(-epsilon, epsilon);   
    float t1 = sdf(p + e.yxx), t2 = sdf(p + e.xxy);
    float t3 = sdf(p + e.xyx), t4 = sdf(p + e.yyy);

    float curv = .25/e.y*(t1 + t2 + t3 + t4 - 4.0 * sdf(p));
    return vec4(normalize(e.yxx*t1 + e.xxy*t2 + e.xyx*t3 + e.yyy*t4), curv);
}

vec3 Lighting(vec3 n, vec3 rayDir, vec3 reflectDir, vec3 pos)
{
    float diff = max(0.0, dot(LIGHT, n));
    float spec = pow(max(0.0, dot(reflectDir, LIGHT)), 10.0);
    float rim = (1.0 - max(0.0, dot(-n, rayDir)));

    return vec3(diff, spec, rim)*0.5; 
}

float TriplanarTexture(vec3 pos, vec3 n)
{
    return 0.0; 
}

float BackGround(vec3 rayDir)
{
    float sun = smoothstep(1.0, 0.0, clamp(length(rayDir - LIGHT), 0.0, 1.0));
    
    return sun*0.5;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 cameraOrigin = vec3(0.0, 0.0, 0.0);
    
    cameraOrigin.x = sin(time*0.25 + 2.0) * (6.0 + sin(time * 0.1));
    cameraOrigin.y = sin(time*0.3) + 3.;
    cameraOrigin.z = cos(time*0.25 + 2.0) * (6.0 + sin(time * 0.15)) ; 
    
    vec3 cameraTarget = vec3(0.0, 0.25, -1.0);
    
    vec2 screenPos = uv * 2.0 - 1.0;
    
    screenPos.x *= resolution.x/resolution.y;
    
    mat3 cam = SetCamera(cameraOrigin, cameraTarget, sin(time*0.15)*0.5);
    
    vec3 rayDir = cam*normalize(vec3(screenPos.xy,2.0));
    vec3 dist = RayMarch(rayDir, cameraOrigin);
    
    float res;
    float backGround = BackGround(rayDir);
    
    if(dist.x < epsilon)
    {
        vec3 pos = cameraOrigin + dist.y*rayDir;
        vec4 n = NorCurv(pos);
        float ao = AO(pos, n.xyz);
        vec3 r = reflect(rayDir, n.xyz);
        vec3 l = Lighting(n.xyz, rayDir, r, pos);
        
        float col = TriplanarTexture(pos, n.xyz);
        col *= n.w*0.5+0.5;
        col *= ao;
        col += ao * (l.x + l.y);
        col += l.z*0.75;
        col += BackGround(n.xyz)*0.25;

        res = col;
    }
    else
    {
        res = backGround; 
    }
    
    glFragColor = vec4(vec3(res), 1.0);
}
