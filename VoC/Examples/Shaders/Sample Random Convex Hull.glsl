#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdtfDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define float2        vec2
#define float3        vec3
#define float4        vec4
#define float2x2    mat2x2
#define float3x3    mat3x3
#define float4x4    mat4x4

#define int2        ivec2
#define int3        ivec3
#define int4        ivec4

#define Any                any
#define All                all
#define Abs                abs
#define ACos            acos
#define ASin            asin
#define ASinH            asinh
#define ACosH            acosh
#define ATan            atan            // result in range [-Pi...+Pi]
#define BitScanReverse    findMSB
#define BitScanForward    findLSB
#define ATanH            atanh
#define Clamp            clamp
#define Ceil            ceil
#define Cos                cos
#define CosH            cosh
#define Cross            cross
#define Distance        distance
#define Dot                dot
#define Exp                exp
#define Exp2            exp2
#define Fract            fract
#define Floor            floor
#define IsNaN            isnan
#define IsInfinity        isinf
#define IsFinite( x )    (! IsInfinity( x ) && ! IsNaN( x ))
#define InvSqrt            inversesqrt
#define IntLog2            BitScanReverse
#define Length            length
#define Lerp            mix
#define Ln                log
#define Log2            log2
#define Log( x, base )    (Ln(x) / Ln(base))
#define Log10( x )        (Ln(x) * 0.4342944819032518)
#define Min                min
#define Max                max
#define Mod                mod
#define MatInverse        inverse
#define MatTranspose    transpose
#define Normalize        normalize
#define Pow                pow
#define Round            round
#define Reflect            reflect
#define Refract            refract
#define Step            step
#define SmoothStep        smoothstep
#define Saturate( x )    clamp( x, 0.0, 1.0 )
#define Sqrt            sqrt
#define Sin                sin
#define SinH            sinh
#define SignOrZero        sign
#define Tan                tan
#define TanH            tanh
#define Trunc            trunc
#define ToUNorm( x )    ((x) * 0.5 + 0.5)
#define ToSNorm( x )    ((x) * 2.0 - 1.0)
//----------------------------------------------

struct quat
{
    float4    data;
};
    
quat  QIdentity ()
{
    quat    ret;
    ret.data = float4( 0.0, 0.0, 0.0, 1.0 );
    return ret;
}

float3  QMul (const quat left, const float3 right)
{
    float3    q    = left.data.xyz;
    float3    uv    = Cross( q, right );
    float3    uuv    = Cross( q, uv );

    return right + ((uv * left.data.w) + uuv) * 2.0;
}

quat  QInverse (const quat q)
{
    quat    ret;
    ret.data.xyz = -q.data.xyz;
    ret.data.w   = q.data.w;
    return ret;
}

quat  QRotationY (const float angleRad)
{
    quat    q;
    float    a = angleRad * 0.5;

    q.data = float4( 0.0, Sin(a), 0.0, Cos(a) );
    return q;
}
//----------------------------------------------

struct Ray
{
    float3    origin;        // camera (eye, light, ...) position
    float3    dir;        // normalized direction
    float3    pos;        // current position
    float    t;
};

Ray        Ray_Create (const float3 origin, const float3 direction, const float tmin)
{
    Ray    result;
    result.origin    = origin;
    result.t        = tmin;
    result.dir        = direction;
    result.pos        = origin + direction * tmin;
    return result;
}

Ray        Ray_FromScreen (const float3 origin, const quat rotation, const float fovX, const float nearPlane,
                        const int2 screenSize, const int2 screenCoord)
{
    float2    scr_size    = float2(screenSize);
    float2    coord        = float2(screenCoord);

    float    ratio        = scr_size.y / scr_size.x;
    float     fovY         = fovX * ratio;
    float2     scale        = nearPlane / Cos( float2(fovX, fovY) * 0.5 );
    float2     uv             = (coord - scr_size * 0.5) / (scr_size.x * 0.5) * scale;

    Ray    ray;
    ray.origin    = origin;
    ray.dir        = Normalize( QMul( rotation, Normalize( float3(uv.x, uv.y, -0.5) )));
    ray.pos        = origin + ray.dir * nearPlane;
    ray.t        = nearPlane;

    return ray;
}

void    Ray_Move (inout Ray ray, const float length)
{
    ray.t   += length;
    ray.pos  = ray.origin + ray.dir * ray.t;
}
//----------------------------------------------

float4 _DHashScale ()  { return float4( 0.1031, 0.1030, 0.0973, 0.1099 ); }

float DHash11 (const float p)
{
    float3 p3 = Fract( float3(p) * _DHashScale().x );
    p3 += Dot( p3, p3.yzx + 19.19 );
    return Fract( (p3.x + p3.y) * p3.z );
}

float2 DHash21 (const float p)
{
    float3 p3 = Fract( float3(p) * _DHashScale().xyz );
    p3 += Dot( p3, p3.yzx + 19.19 );
    return Fract( (p3.xx + p3.yz) * p3.zy );
}
//----------------------------------------------

float3  CM_RotateVec (const float3 c, const int face)
{
    switch ( face )
    {
        case 0 : return float3( c.z,  c.y, -c.x);    // X+
        case 1 : return float3(-c.z,  c.y,  c.x);    // X-
        case 2 : return float3( c.x, -c.z,  c.y);    // Y+
        case 3 : return float3( c.x,  c.z, -c.y);    // Y-
        case 4 : return float3( c.x,  c.y,  c.z);    // Z+
        case 5 : return float3(-c.x,  c.y, -c.z);    // Z-
    }
    return float3(0.0);
}

float3  CM_TangentialSC_Forward (const float2 snormCoord, const int face)
{
    const float    warp_theta        = 0.868734829276;
    const float    tan_warp_theta    = 1.182286685546; //tan( warp_theta );
    float2        coord            = Tan( warp_theta * snormCoord ) / tan_warp_theta;

    return Normalize( CM_RotateVec( float3(coord.x, coord.y, 1.0), face ));
}
//----------------------------------------------

float SDF_Plane (const float3 planePos, const float3 pos)
{
    float3    v = -planePos;
    float    d = Length( v );
    return Dot( v / d, pos ) - d;
}

float3 SDF_Rotate (const float3 position, const quat q)
{
    return QMul( QInverse( q ), position );
}

#define GEN_SDF_NORMAL_FN( _fnName_, _sdf_, _field_ )                          \
    float3 _fnName_ (const float3 pos)                                         \
    {                                                                          \
        const float2    eps  = float2( 0.001, 0.0 );                           \
        float3            norm = float3(                                         \
            _sdf_( pos + eps.xyy ) _field_ - _sdf_( pos - eps.xyy ) _field_,   \
            _sdf_( pos + eps.yxy ) _field_ - _sdf_( pos - eps.yxy ) _field_,   \
            _sdf_( pos + eps.yyx ) _field_ - _sdf_( pos - eps.yyx ) _field_ ); \
        return Normalize( norm );                                              \
    }

#define GEN_SDF_NORMAL_FN2( _fnName_, _sdf_, _field_ )  \
    float3 _fnName_ (const float3 pos)                  \
    {                                                   \
        const float        h     = 0.001;                   \
        const float2    k     = float2(1,-1);            \
        float3            norm = float3(                  \
            k.xyy * _sdf_( pos + k.xyy * h ) _field_ +  \
            k.yyx * _sdf_( pos + k.yyx * h ) _field_ +  \
            k.yxy * _sdf_( pos + k.yxy * h ) _field_ +  \
            k.xxx * _sdf_( pos + k.xxx * h ) _field_ ); \
        return Normalize( norm );                       \
    }

float SDF (const float3 pos)
{
    int            base_seed    = int(time * 0.25);
    float        factor        = Clamp( Fract(time * 0.25) * 2.0, 0.0, 1.0 );
    const int    plane_count    = 16;

    float    dist[2];
    for (int j = 0; j < 2; ++j)
    {
        float    md        = -1.0e+10;
        int        seed    = base_seed + j;

        for (int i = 0; i < plane_count; ++i)
        {
            int        face    = (i + seed) % 6;
            float2    scoord    = DHash21( float(i)*51.85 + float(seed)*2.0 );
            float    radius    = 1.0 + DHash11( float(i)*9.361 + float(seed)*3.94521 ) * 0.5;
            float3    norm    = Normalize( CM_TangentialSC_Forward( scoord, face ));
            float3    plane    = radius * norm;

            md = Max( md, SDF_Plane( plane, pos ));
        }
    
        md = Max( md, Length( pos ) - 3.0);
        dist[j] = md;
    }

    return Lerp(dist[0], dist[1], factor);
}

float SDFScene (float3 pos)
{
    pos = pos - float3(0.0, 0.0, 5.0);
    pos = SDF_Rotate( pos, QRotationY( time*0.3 ));
    return SDF( pos );
}

GEN_SDF_NORMAL_FN2( SDFNormal, SDFScene, )

float4 TraceRay (Ray ray)
{
    const int    max_iter    = 256;
    const float    min_dist    = 0.00625f;
    const float    max_dist    = 100.0;

    int i = 0;
    for (; i < max_iter; ++i)
    {
        float    dist = SDFScene( ray.pos );
        
        Ray_Move( ray, dist );

        if ( Abs(dist) < min_dist || ray.t > max_dist )
            break;
    }

    if ( ray.t > max_dist )
        return float4(0.0, 0.0, 0.3, 1.0);

    float3    norm        = SDFNormal( ray.pos );
    float3    light_dir    = -ray.dir;

    float    shading = Dot( norm, light_dir );
    return float4( shading );
}
//-----------------------------------------------------------------------------

void main(void)
{
    Ray ray = Ray_FromScreen( vec3(0.0, 0.0, 30.0), QIdentity(), radians(90.0), 0.1, int2(resolution.xy), int2(gl_FragCoord.xy) );
    
    glFragColor = TraceRay( ray );
}
