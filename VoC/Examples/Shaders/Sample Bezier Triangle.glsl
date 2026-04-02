#version 420

// original 

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//---------------------------------------------------
//---------------------------------------------------
//
// "Ray-intersection for uni-variate quadratic Bezier triangle"
//
// 'Ray-intersection' instead of 'ray-tracing' becase we are finding the
//  intersection with one primitive with a formula, as opposed to finding
//  intersection with a group of objects with an iterative approach.
//
// 'Uni-variate' because the spline is interpolating scalar values, which
//  we then interpret as the 'height' of the spline at that location.  
//
//  'Quadratic' because the basis functions are a set of 2D quadratic
//  polynomials in Bernstein form.  Yes, the basis functions are
//  intrinsically 2D and quadratic, unlike rectangular Bezier forms.
//
//  'Bezier triangle' because simplex (triangle, tetrahedra, etc) lend 
//  themselves to ray-intersection more easily than rectangular Bezier 
//  forms.  This is because the basis functions in the rectangular case
//  are created by combinations of 1D basis functions that multiply out into
//  higher powers when trying to solve non-axis-aligned ray-intersection.
//  Simplex forms avoid by using intrinsically 2D basis functions.
//
//  This is intended to be more of a educational example than a 'real' 
//  optimized implementation. Currently suffers from some precision 
//  problems and ugly code that I may cleanup later if I feel like it.
//
//  -John Kloetzli, Jr
//  @JJcoolkl
//---------------------------------------------------
//---------------------------------------------------

#define H_FOV_RADIANS 0.785
#define D_BIAS 0.0001

//---------------------------------------------------
// Definition of the quadratic triangular b-spline
//---------------------------------------------------
vec2 v2VertA = vec2( 0.0, 4.0 ); 
vec2 v2VertB = vec2(-4.0,-4.0 );
vec2 v2VertC = vec2( 4.0,-4.0 );
    
//Control points marked by index
float f200 = 2.0;
float f020 = 2.0;
float f002 = 2.0;

float f011 = -2.0;
float f101 = -2.0;
float f110 = -2.0;

//---------------------------------------------------
// Evaluate the b-spline at a given barycentric point
//---------------------------------------------------
float BezierTriangle_Quadratic( const vec3 v3Bary, const vec3 CP_2, const vec3 CP_0 )
{
    return 
        v3Bary.x * v3Bary.x * CP_2.x + 
        v3Bary.y * v3Bary.y * CP_2.y +
        v3Bary.z * v3Bary.z * CP_2.z +
        
        v3Bary.y * v3Bary.z * CP_0.x * 2.0 +
        v3Bary.x * v3Bary.z * CP_0.y * 2.0 + 
        v3Bary.x * v3Bary.y * CP_0.z * 2.0; 
}

//---------------------------------------------------
// Evaluate the normal at a given barycentric point
//---------------------------------------------------
vec3 BezierTriangle_Quadratic_Normal( const vec3 v3Bary, const vec3 CP_2, const vec3 CP_0 )
{
    //directional derivatives for vectors AB and AC
    float fDirAB = 
        (CP_2.x - CP_0.z) * v3Bary.x +
        (CP_0.z - CP_2.y) * v3Bary.y +
        (CP_0.y - CP_0.x) * v3Bary.z;
    
    float fDirAC = 
        (CP_2.x - CP_0.y) * v3Bary.x +
        (CP_0.z - CP_0.x) * v3Bary.y +
        (CP_0.y - CP_2.z) * v3Bary.z;
    
    //Reconstruct vectors AB and AC (are known in world space)
    vec3 AB = vec3( v2VertA - v2VertB, fDirAB );
    vec3 AC = vec3( v2VertA - v2VertC, fDirAC );
        
    vec3 Normal = normalize( cross( AB, AC ) );
    return Normal;
}

//---------------------------------------------------
// Convert a 2d Cartesian point to barycentric (relative to spline verts)
//---------------------------------------------------
vec3 CartToBary( vec2 v2Cart )
{
    vec2 v0 = v2VertB - v2VertA;
    vec2 v1 = v2VertC - v2VertA;
    vec2 v2 = v2Cart - v2VertA;
    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);
    float denom = d00 * d11 - d01 * d01;
    
    vec3 v3Bary;
    v3Bary.y = (d11 * d20 - d01 * d21) / denom;
    v3Bary.z = (d00 * d21 - d01 * d20) / denom;
    v3Bary.x = 1.0 - v3Bary.y - v3Bary.z;
    
    return v3Bary;
}

//---------------------------------------------------
// Intersect camera ray with bezier tri.
//---------------------------------------------------
vec2 LineISect( const vec2 S1, const vec2 S2, const vec2 E1, const vec2 E2 )
{
    vec3 A1, A2;
    A1.x = S2.y - S1.y;
    A1.y = S1.x - S2.x;
    A1.z = A1.x * S1.x + A1.y * S1.y;
    
    A2.x = E2.y - E1.y;
    A2.y = E1.x - E2.x;
    A2.z = A2.x * E1.x + A2.y * E1.y;
    
    float fDet = A1.x * A2.y - A2.x * A1.y;
    if( abs(fDet) < 0.001 )
        return vec2(0.0, 0.0);
    vec2 v2Ret;
    v2Ret.x = ((A2.y*A1.z) - (A1.y*A2.z)) / fDet;
    v2Ret.y = ((A1.x*A2.z) - (A2.x*A1.z)) / fDet;
    return v2Ret;
}

vec4 BezierTriISect( const vec3 v3CameraPos, const vec3 v3LookDir, vec3 CP_2, vec3 CP_0 )
{
    vec2 v2LookPt = v3CameraPos.xy + v3LookDir.xy;
    
    //This is a hacky brute-force way of finding limits of triangle bounding retion.  
    // I will probably re-write this with a better approach.
    vec2 v2PosA = LineISect( v2VertA, v2VertB, v3CameraPos.xy, v2LookPt );
    vec2 v2PosB = LineISect( v2VertB, v2VertC, v3CameraPos.xy, v2LookPt );
    vec2 v2PosC = LineISect( v2VertC, v2VertA, v3CameraPos.xy, v2LookPt );
    
    vec2 v2MinA = vec2( min( v2VertA.x, v2VertB.x ), min( v2VertA.y, v2VertB.y ) ) - D_BIAS;
    vec2 v2MinB = vec2( min( v2VertB.x, v2VertC.x ), min( v2VertB.y, v2VertC.y ) ) - D_BIAS;
    vec2 v2MinC = vec2( min( v2VertC.x, v2VertA.x ), min( v2VertC.y, v2VertA.y ) ) - D_BIAS;
    
    vec2 v2MaxA = vec2( max( v2VertA.x, v2VertB.x ), max( v2VertA.y, v2VertB.y ) ) + D_BIAS;
    vec2 v2MaxB = vec2( max( v2VertB.x, v2VertC.x ), max( v2VertB.y, v2VertC.y ) ) + D_BIAS;
    vec2 v2MaxC = vec2( max( v2VertC.x, v2VertA.x ), max( v2VertC.y, v2VertA.y ) ) + D_BIAS;
    
    bool bAValid = 
        v2PosA.x >= v2MinA.x && v2PosA.x <= v2MaxA.x && 
        v2PosA.y >= v2MinA.y && v2PosA.y <= v2MaxA.y;
    
    bool bBValid =
        v2PosB.x >= v2MinB.x && v2PosB.x <= v2MaxB.x &&
        v2PosB.y >= v2MinB.y && v2PosB.y <= v2MaxB.y;
    
    bool bCValid =
        v2PosC.x >= v2MinC.x && v2PosC.x <= v2MaxC.x && 
        v2PosC.y >= v2MinC.y && v2PosC.y <= v2MaxC.y;
    
    
    
    float fCamDistA = (v2PosA.x - v3CameraPos.x) / v3LookDir.x;
    float fCamDistB = (v2PosB.x - v3CameraPos.x) / v3LookDir.x;
    float fCamDistC = (v2PosC.x - v3CameraPos.x) / v3LookDir.x;
    
    vec3 v3Start, v3End;
    if( bAValid && bBValid )
    {
        v3Start = v3CameraPos + v3LookDir * min( fCamDistA, fCamDistB );
        v3End = v3CameraPos + v3LookDir * max( fCamDistA, fCamDistB );
    }else if( bBValid && bCValid )
    {
        v3Start = v3CameraPos + v3LookDir * min( fCamDistB, fCamDistC );
        v3End = v3CameraPos + v3LookDir * max( fCamDistB, fCamDistC );
    }else if( bCValid && bAValid )
    {
        v3Start = v3CameraPos + v3LookDir * min( fCamDistC, fCamDistA );
        v3End = v3CameraPos + v3LookDir * max( fCamDistC, fCamDistA );
    }else{
        //no intersection!
        return vec4( 0.0, 0.0, 0.0, 2.0 );
    }
    
    vec3 S = CartToBary( v3Start.xy );
    vec3 E = CartToBary( v3End.xy );
    
    //Plug in eye ray and solve variables for root finding.
    vec3 ES = E - S;
    
    float fA = dot( ES * ES, CP_2 ) + 2.0*dot( vec3(ES.y*ES.z, ES.x*ES.z, ES.x*ES.y), CP_0 );
    
    float fB = - (v3End.z - v3Start.z) + 2.0*( 
        dot( ES*S, CP_2 ) + 
        dot( vec3((ES.y*S.z + ES.z*S.y), (ES.x*S.z + ES.z*S.x), (ES.x*S.y + ES.y*S.x)), CP_0 ) );
    
    float fC = - v3Start.z + dot( S*S, CP_2 ) +
        2.0*dot( vec3(S.y*S.z,S.x*S.z,S.x*S.y), CP_0 );
    
    //Actual root finding
    float fRoot = fB*fB - 4.0*fA*fC;
    if( fRoot >= 0.0 )
    {
        float fRootA = (-fB + sqrt( fRoot ) ) /( 2.0 * fA );
        float fRootB = (-fB - sqrt( fRoot ) ) /( 2.0 * fA );
        
        if( fRootA >= 0.0 && fRootA <= 1.0 )
        {
            if( fRootB >= 0.0 )
                fRootA = min( fRootB, fRootA );
            
            return vec4( S + fRootA*ES, fRootA );
        }
        
        if( fRootB >= 0.0 && fRootB <= 1.0 )
            return vec4( S + fRootB*ES, fRootB );
    }
    
    return vec4(0.0, 0.0, 0.0, 2.0);
}

//---------------------------------------------------
// Compute color based on bezier tri intersection + lighting
//---------------------------------------------------
vec4 ComputeBezierColor( vec3 v3CameraPos, vec3 v3LookDir, vec3 CP_2, vec3 CP_0 )
{
    vec4 v4ISect = BezierTriISect( v3CameraPos, v3LookDir, CP_2, CP_0 );
    
    vec3 v3Warm = vec3( 238.0, 197.0, 169.0 ) / 255.0;
    vec3 v3Cool = vec3( 202.0, 185.0, 241.0 ) / 255.0;
    vec3 v3Ambient = vec3( .5,.5,.5 );
    
    vec3 v3WarmPos = normalize( vec3(.7, .7, .7) ); 
    vec3 v3CoolPos = normalize( vec3(-.7, -.7, -.3) ); 
    
    vec3 v3Color = vec3(0.0,0.0,0.0);
    float fAlpha = 0.0;
    if( v4ISect.w <= 1.0 )
    {
        vec3 v3Norm = BezierTriangle_Quadratic_Normal( v4ISect.xyz, CP_2, CP_0 );
        
        float fWarm = max( 0.0, dot( v3Norm, v3WarmPos ) );
        float fCool = max( 0.0, dot( v3Norm, v3CoolPos ) );
        
        v3Color = 0.2*v3Ambient + v3Warm*fWarm + v3Cool*fCool;
        
        fAlpha = 1.0;
    }
    return vec4( v3Color.xyz, fAlpha );
}

//---------------------------------------------------
// Overlay management
//---------------------------------------------------
float SphereISect( vec3 v3Camera, vec3 v3LookDir, vec4 v4Sphere )
{       
    vec3 v3Diff = v3Camera - v4Sphere.xyz;
    float fA = dot(v3LookDir, v3Diff);
    float fB = length( v3Diff );
        
    float fDelta = .0001;
    float fSqrt = fA*fA - (fB*fB);
    float fInner = fSqrt + v4Sphere.w*v4Sphere.w;
    float fOuter = fSqrt + (v4Sphere.w+fDelta) * (v4Sphere.w+fDelta);
     
    return clamp( mix( 0.0, 1.0, fOuter / (fOuter - fInner ) ), 0.0, 1.0 );
}

//---------------------------------------------------
// Compute overlay color
//---------------------------------------------------
float ComputeOverlay( vec3 v3Camera, vec3 v3LookAt, vec3 CP_2, vec3 CP_0 )
{
    float fDot = 0.0;
    fDot += SphereISect( v3Camera, v3LookAt, vec4( v2VertA,                 CP_2.x, .2) );
    fDot += SphereISect( v3Camera, v3LookAt, vec4( (v2VertA+v2VertB) * 0.5,    CP_0.z, .2) );
    fDot += SphereISect( v3Camera, v3LookAt, vec4( (v2VertC+v2VertA) * 0.5,    CP_0.y, .2) );
    fDot += SphereISect( v3Camera, v3LookAt, vec4( v2VertB,                 CP_2.y, .2) );
    fDot += SphereISect( v3Camera, v3LookAt, vec4( (v2VertB+v2VertC) * 0.5,    CP_0.x, .2) );
    fDot += SphereISect( v3Camera, v3LookAt, vec4( v2VertC,                 CP_2.z, .2) );
        
    return fDot;
}

//---------------------------------------------------
// Camera management
//---------------------------------------------------
vec3 GetCameraPos()
{
    vec2 v2Mouse = vec2( 0.0 / resolution.xy ) * 10.0;
    vec3 v3Pos = vec3(
        sin(v2Mouse.x + time*.1), 
        cos(v2Mouse.x + time*.1), 1.0 );
    
    return normalize( v3Pos ) * 10.0;
}
vec3 GetLookDir( vec3 v3CameraPos )
{
    float fScale = tan( H_FOV_RADIANS );
    float fAspectRatio = resolution.x / resolution.y;
    vec2 v2Screen = (2.0 * (gl_FragCoord.xy / resolution.xy) - 1.0) * vec2(fAspectRatio, 1.0) * fScale;
   
    vec3 v3Up = vec3(0.0, 0.0, 1.0);
    vec3 v3Look = normalize( -v3CameraPos );
    vec3 v3Left = cross( v3Up, v3Look );
    v3Up = cross( v3Look, v3Left );
    
    v3Look += v3Left * v2Screen.x + v3Up * v2Screen.y;
    return normalize( v3Look );
}

//---------------------------------------------------
//---------------------------------------------------
void main(void)
{
    float fAspectRatio = resolution.x / resolution.y;
    vec2 uv = (2.0 * (gl_FragCoord.xy / resolution.xy) - 1.0) * vec2(fAspectRatio, 1.0);
    
    vec3 v3Camera = GetCameraPos();
    vec3 v3LookDir = GetLookDir( v3Camera );
    
    float fT = time;
    vec3 CP_2 = vec3( f200 * sin(fT), f020 * sin(fT*1.2), f002 * sin(fT)*.9 );
    vec3 CP_0 = vec3( f011 * sin(fT*2.0), f101*sin(fT*1.1), f110 * sin(fT) );
    
    //Compute spline surface color
    vec4 v4Color = ComputeBezierColor( v3Camera, v3LookDir, CP_2, CP_0 );
    vec4 v4Final = mix( vec4( .5, .5, .5, 1.0 ), v4Color, v4Color.a );
    
    //Compute overlay
    float fOverlay = ComputeOverlay( v3Camera, v3LookDir, CP_2, CP_0 );
    
    vec4 v4OverlayColor = vec4(.7,.7,.7,1);
    v4Final = mix( v4Final, v4OverlayColor, fOverlay ); 
    
    glFragColor = v4Final;
}

