#version 420

// original https://www.shadertoy.com/view/Nts3W2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float epsilon = 0.01;
const float pi = 3.14159265359;
const float halfpi = 1.57079632679;
const float twopi = 6.28318530718;

#define LIGHT normalize(vec3(1.0, 1.0, 0.0))

//----------------------------------------------------------------------------------
//  from SDF Editor
//----------------------------------------------------------------------------------

float pCylinder(float r, float h, vec3 p)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
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
vec3 ReCe_1 = vec3( 4.77, -1.31, 4.75 );
vec3 TrIn_2 = vec3( 0, 0, 0 );
vec3 TrIn_3 = vec3( 1, -0.13, 0 );
mat3 RoIn_4 = mat3(0, -0, -1, 1, 0, -0, 0, -1, 0);
float CyRa_5 = 0.06;
float CyHe_6 = 4.;
vec3 TrIn_7 = vec3( 0, 0.11, 0 );
mat3 RoIn_8 = mat3(0, -0.707107, 0.707107, 1, 0, -0, -0, 0.707107, 0.707107);
float CyRa_9 = 0.06;
float CyHe_10 = 4.;
vec3 TrIn_11 = vec3( 0, 0.25, -0.01 );
mat3 RoIn_12 = mat3(0, -0.707107, -0.707107, 1, 0, -0, 0, -0.707107, 0.707107);
float CyRa_13 = 0.06;
float CyHe_14 = 4.;
vec3 TrIn_15 = vec3( 0, 0, 0 );
vec3 TrIn_16 = vec3( -1, 0, -1 );
mat3 RoIn_17 = mat3(0, -0.707107, -0.707107, 1, 0, -0, 0, -0.707107, 0.707107);
float CyRa_18 = 1.;
float CyHe_19 = 0.2;
float CyRa_20 = 0.6;
float CyHe_21 = 0.25;
vec3 TrIn_22 = vec3( -1, 0, 1 );
mat3 RoIn_23 = mat3(0, -0.707107, 0.707107, 1, 0, -0, -0, 0.707107, 0.707107);
float CyRa_24 = 1.;
float CyHe_25 = 0.2;
float CyRa_26 = 0.6;
float CyHe_27 = 0.25;
vec3 TrIn_28 = vec3( 0, 0, 0 );
vec3 TrIn_29 = vec3( 1, 0, 1 );
mat3 RoIn_30 = mat3(0, -0.707107, -0.707107, 1, 0, -0, 0, -0.707107, 0.707107);
float CyRa_31 = 0.6;
float CyHe_32 = 0.25;
float CyRa_33 = 1.;
float CyHe_34 = 0.2;
vec3 TrIn_35 = vec3( 1, 0, -1 );
mat3 RoIn_36 = mat3(0, -0.707107, 0.707107, 1, 0, -0, -0, 0.707107, 0.707107);
float CyRa_37 = 0.6;
float CyHe_38 = 0.25;
float CyRa_39 = 1.;
float CyHe_40 = 0.2;
vec3 TrIn_41 = vec3( -1, -0.12, 0 );
mat3 RoIn_42 = mat3(1, -0, 0, 0, 0, -1, 0, 1, 0);
float CyRa_43 = 0.06;
float CyHe_44 = 4.;
vec3 TrIn_45 = vec3( 0, -0.01, -1 );
mat3 RoIn_46 = mat3(0, -1, 0, 1, 0, -0, 0, 0, 1);
float CyRa_47 = 0.06;
float CyHe_48 = 4.;
vec3 TrIn_49 = vec3( 0, 0.01, 1 );
mat3 RoIn_50 = mat3(0, -1, 0, 1, 0, -0, 0, 0, 1);
float CyRa_51 = 0.06;
float CyHe_52 = 4.;

float sdf(vec3 p0)
{
    float d1;
    float d2;
    float d3;
    float d4;
    float d5;
    float d6;
    float d7;
    float d8;
    float d9;
    float d10;
    float d11;
    float d12;
    float d13;
    float d14;

    {
        vec3 p1 = mRepInf(ReCe_1, p0);
        {
            vec3 p2 = mTranslation(TrIn_2, p1);
            {
                vec3 p3 = mTranslation(TrIn_3, p2);
                {
                    vec3 p4 = mRotation(RoIn_4, p3);
                    d1 = pCylinder(CyRa_5, CyHe_6, p4);
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_7, p2);
                {
                    vec3 p4 = mRotation(RoIn_8, p3);
                    d2 = pCylinder(CyRa_9, CyHe_10, p4);
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_11, p2);
                {
                    vec3 p4 = mRotation(RoIn_12, p3);
                    d3 = pCylinder(CyRa_13, CyHe_14, p4);
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_15, p2);
                {
                    vec3 p4 = mTranslation(TrIn_16, p3);
                    {
                        vec3 p5 = mRotation(RoIn_17, p4);
                        d4 = pCylinder(CyRa_18, CyHe_19, p5);
                        d5 = pCylinder(CyRa_20, CyHe_21, p5);
                    }
                }
                {
                    vec3 p4 = mTranslation(TrIn_22, p3);
                    {
                        vec3 p5 = mRotation(RoIn_23, p4);
                        d6 = pCylinder(CyRa_24, CyHe_25, p5);
                        d7 = pCylinder(CyRa_26, CyHe_27, p5);
                    }
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_28, p2);
                {
                    vec3 p4 = mTranslation(TrIn_29, p3);
                    {
                        vec3 p5 = mRotation(RoIn_30, p4);
                        d8 = pCylinder(CyRa_31, CyHe_32, p5);
                        d9 = pCylinder(CyRa_33, CyHe_34, p5);
                    }
                }
                {
                    vec3 p4 = mTranslation(TrIn_35, p3);
                    {
                        vec3 p5 = mRotation(RoIn_36, p4);
                        d10 = pCylinder(CyRa_37, CyHe_38, p5);
                        d11 = pCylinder(CyRa_39, CyHe_40, p5);
                    }
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_41, p2);
                {
                    vec3 p4 = mRotation(RoIn_42, p3);
                    d12 = pCylinder(CyRa_43, CyHe_44, p4);
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_45, p2);
                {
                    vec3 p4 = mRotation(RoIn_46, p3);
                    d13 = pCylinder(CyRa_47, CyHe_48, p4);
                }
            }
            {
                vec3 p3 = mTranslation(TrIn_49, p2);
                {
                    vec3 p4 = mRotation(RoIn_50, p3);
                    d14 = pCylinder(CyRa_51, CyHe_52, p4);
                }
            }
        }
    }
    return oUnion(oSubtraction(d9, d8), oUnion(oSubtraction(d11, d10), oUnion(d2, oUnion(d3, oUnion(d1, oUnion(oSubtraction(d6, d7), oUnion(oSubtraction(d4, d5), oUnion(d12, oUnion(d13, d14)))))))));
}

vec3 RayMarch(vec3 rayDir, vec3 cameraOrigin)
{
    const int maxItter = 128;
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
        cameraOrigin.y = sin(time*0.3) + 12.5;
        cameraOrigin.z = cos(time*0.25 + 2.0) * (6.0 + sin(time * 0.15)) - 10. ; 
    
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
