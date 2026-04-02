#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XsdcDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 3D Motion Illusion Test - @P_Malin
// https://www.shadertoy.com/view/XsdcDr

// Inspired by patterns from @AkiyoshiKitaoka mapped on a 3D scene.
// https://twitter.com/AkiyoshiKitaoka/status/967758875649699841
// https://twitter.com/AkiyoshiKitaoka/status/970964297550520320
// https://twitter.com/AkiyoshiKitaoka/status/969510301925236736

//#define REVERSE_DIRECTION

float MAX_DIST = 1000.0;

vec2 GetWindowCoord( const in vec2 vUV )
{
    vec2 vWindow = vUV * 2.0 - 1.0;
    vWindow.x *= resolution.x / resolution.y;

    return vWindow;    
}

vec3 GetCameraRayDir( const in vec2 vWindow, const in vec3 vCameraPos, const in vec3 vCameraTarget )
{
    vec3 vForward = normalize(vCameraTarget - vCameraPos);
    vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
    vec3 vUp = normalize(cross(vForward, vRight));
                              
    float fPersp = 3.0;
    vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * fPersp);

    return vDir;
}

vec2 Scene_GetDistance( vec3 vPos )
{
    vec2 vResult = vec2( MAX_DIST, 0.0 );

    float fFloorPlaneDist = 10.0 + vPos.y;
    if ( fFloorPlaneDist < vResult.x )
    {
        vResult = vec2( fFloorPlaneDist, vPos.x * 1.5 );
    }

    float fCeilPlaneDist = 18.6 - vPos.y;
    if ( fCeilPlaneDist < vResult.x )
    {
        vResult = vec2( fCeilPlaneDist, vPos.x * 1.5 );
    }
    
    float fTunnelDist = 20.0 - length(vPos.xy);        
    if ( fTunnelDist < vResult.x )
    {
        vResult = vec2( fTunnelDist, atan(vPos.x, vPos.y) * 150.0 / (3.14 * 2.0) );
    }

    vec3 vRailDomain = vPos;
    vRailDomain.x = abs( vRailDomain.x );
    
    float fRailDist = length(vRailDomain.xy - vec2(10.0, -9.0)) - 1.0;
    if ( fRailDist < vResult.x )
    {
        vResult = vec2( fRailDist, 0.0 );
    }

    float fSideRailDist = length(vRailDomain.xy - vec2(19.0, -1.5)) - 2.0;
    if ( fSideRailDist < vResult.x )
    {
        vResult = vec2( fSideRailDist, 0.0 );
    }
        
    return vResult;
}

vec3 Scene_GetNormal( const in vec3 vPos )
{
    const float fDelta = 0.0001;
    vec2 e = vec2( -1, 1 );
    
    vec3 vNormal = 
        Scene_GetDistance( e.yxx * fDelta + vPos ).x * e.yxx + 
        Scene_GetDistance( e.xxy * fDelta + vPos ).x * e.xxy + 
        Scene_GetDistance( e.xyx * fDelta + vPos ).x * e.xyx + 
        Scene_GetDistance( e.yyy * fDelta + vPos ).x * e.yyy;
    
    return normalize( vNormal );
}   

vec2 Scene_Trace( vec3 vRayOrigin, vec3 vRayDir, float minDist, float maxDist )
{    
    vec2 vResult = vec2(0, 0);
    
    float t = minDist;
    const int kRaymarchMaxIter = 64;
    for(int i=0; i<kRaymarchMaxIter; i++)
    {        
        float epsilon = 0.0001 * t;
        vResult = Scene_GetDistance( vRayOrigin + vRayDir * t );
        if ( abs(vResult.x) < epsilon )
        {
            break;
        }
                        
        if ( t > maxDist )
        {
            t = maxDist;
            break;
        }               
        
        t += vResult.x;
    }
    
    vResult.x = t;
    
    return vResult;
}    

vec3 MotionTextureGradient( float f )
{
    vec3 cols[] = vec3[](
        vec3(1,0,0),
        vec3(1,0,1),
        vec3(0.95,0,1) * 0.75
        );

    f *= float( cols.length() );    

    int c1 = int( floor(f) ) % cols.length();
    int c2 = (c1 + 1) % cols.length();
    float b = clamp( f - float(c1), 0.0, 1.0 );
    
    //b = smoothstep(0.0,1.0,b);
    return mix( cols[c1], cols[c2], b );    
}

vec3 MotionTexture( vec2 vUV )
{
    float x = fract( vUV.x );

    float fOffset = floor( x * 2.0 ) / 2.0;
    float y = fract( vUV.y + fOffset );
    
    return MotionTextureGradient( y );
}

vec3 GetSceneColour( const in vec3 vRayOrigin,  const in vec3 vRayDir )
{
    float theta = atan(vRayDir.x, vRayDir.y);
    vec2 vScene = Scene_Trace( vRayOrigin, vRayDir, 0.0, MAX_DIST );
    float fDist = vScene.x;
    vec3 vPos = vRayOrigin + vRayDir * fDist;
    
    vec3 vNormal = Scene_GetNormal( vPos );
    vec2 vUV = vScene.yx * vec2(0.1, 0.05); 
    
    if ( fDist > 350.0 )
    {
        vUV = vec2(0);
    }   

#ifdef REVERSE_DIRECTION
    vUV.y = 1.0 - vUV.y;
#endif    
    
    vec3 vTex = MotionTexture(vUV + 0.25);
    
    vTex = vTex * vTex;
    float t = fDist * fDist;
    float fFog = 1.0 - exp2( -t * 0.00005 );
    vec3 vFogColor = vec3(0.0);
    vec3 vResult = mix( vTex, vFogColor, fFog );
    
    return sqrt(vResult);
}

void main(void)
{
    vec2 vUV = gl_FragCoord.xy / resolution.xy;

    vec3 vCameraPos = vec3(0.0, 0.0, 0.0);
    vec3 vCameraTarget = vec3(0.0, 0.0, 10.0);
    
    vec3 vRayOrigin = vCameraPos;
    vec3 vRayDir = GetCameraRayDir( GetWindowCoord(vUV), vCameraPos, vCameraTarget );
    
    vec3 vResult = GetSceneColour(vRayOrigin, vRayDir);
        
    glFragColor = vec4(vResult, 1.0);
}
