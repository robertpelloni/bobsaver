#version 420

// original https://www.shadertoy.com/view/wslyzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float MAX_GRADIENT = 55.0; // should be actual maximum rate of change of GetHeight()
#define DEBUG_MAX_GRADIENT 0 // make MAX_GRADIENT as low as possible without letting any white appear
float GetHeight( vec2 uv )
{
    if ( uv.x < 0.0 )
        return 1.0;

    float updown = sin( uv.x * 12.0 + time * 0.6 ) * mix( 1.0, 0.2, uv.x ) * 0.12;
    float yspread = (uv.y - 0.5) * mix( 1.0, 0.1, uv.x ) + 0.5;
    float leftright = sin( (yspread + updown) * 20.0 );
    
    float checker = sin( (uv.x + time * 0.05) * 40.0 ) * sin( uv.y * 10.0 - time * 1.0 ) * 0.5 + 0.5;
    
    float yCenterToEdge = (uv.y - 0.5) / 0.5;
    yCenterToEdge *= yCenterToEdge;
    float xpow = mix( 0.17, 0.25, yCenterToEdge );
    
    float phase = fract( pow( uv.x, xpow ) * 40.0 + leftright * 0.32 + checker * 0.2 + time * 0.1 * 1.4 );
    
    //phase = phase * phase;
    
    float wave = cos( phase * 2.0 * 3.14159 ) * 0.5 + 0.5;
    //wave += cos( phase * 2.0 * 3.14159 * 14.0 ) * 0.005;
    
    //wave = pow( wave, 4.0 );
    
    float height = mix( 1.0, wave, pow( uv.x, 0.8 ) );
    return height;
}

const float BUMP_STRENGTH = 0.03;

float GetUnshadowedLightFrac( vec2 uv, float startHeight, vec3 lightDir )
{
    const float SOFT_SHADOW_SLOPE = 4.0;
    const float DIST_THRESHOLD = 0.001;

    lightDir /= length( lightDir.xy ); // MAX_GRADIENT is in XY direction only
    lightDir.z /= BUMP_STRENGTH;
    
    vec3 pos = vec3( uv, startHeight ) + lightDir * DIST_THRESHOLD;
    float traveledDist = DIST_THRESHOLD;
    
    float softShadowAmount = 1.0;
    
    for ( int step = 0; step < 50; step++ )
    {
        float height = GetHeight( pos.xy );
        if ( height > pos.z )
            return 0.0f;
        float diff = pos.z - height;
        
        softShadowAmount = min( diff / (SOFT_SHADOW_SLOPE * traveledDist), softShadowAmount );
        
        float minDistToHit = diff / MAX_GRADIENT + DIST_THRESHOLD;
        traveledDist += minDistToHit;
        
        pos += lightDir * minDistToHit;
        if ( pos.z > 1.0 + SOFT_SHADOW_SLOPE )
            break;
    }
    
    return softShadowAmount;
}

vec3 Color( float x )
{
    const vec3 c0 = vec3( 1.0, 0.8, 0.5 ) * 1.8;
    const vec3 c1 = vec3( 1.0, 0.5, 0.25 ) * 1.1;
    const vec3 c2 = vec3( 0.5, 0.15, 0.4 ) * 0.8;
    const vec3 c3 = vec3( 0.2, 0.04, 0.35 ) * 0.5;
    const vec3 c4 = vec3( 0.001, 0.003, 0.05 );
    if ( x < 0.4 )
    {
        if ( x < 0.1 )
            return mix( c0, c1, x / 0.1 );
        else
            return mix( c1, c2, (x - 0.1) / 0.3 );
    }
    else
    {
        if ( x < 0.6 )
            return mix( c2, c3, (x - 0.4) / 0.2 );
        else
        {
            x = min( x, 1.0 );
            return mix( c3, c4, (x - 0.6) / 0.4 );
        }
    }
}

float sinsin( vec2 uv )
{
    return min( abs( sin( uv.x ) * sin( uv.y ) ) * 1.2, 1.0 );
}

float Glitter( vec2 uv )
{
    uv *= 0.8;
    uv.x *= resolution.x / resolution.y;
    
    uv.x += sin( uv.y * 20.0 ) * 0.03;
    float x = sinsin( (uv.xx * vec2( 0.64, 0.77 ) + uv.yy * vec2( 0.77, -0.64 )) * 300.0 );
    x *= sinsin( (uv.xx * vec2( 0.34, 0.94 ) + uv.yy * vec2( 0.94, -0.34 )) * 211.0 );
    x *= sinsin( (uv.xx * vec2( 0.99, 0.12 ) + uv.yy * vec2( 0.12, -0.99 )) * 73.0 );
    // return x; // to see what's going on here
    return pow( x * 1.015, 100.0 );
}

void main(void)
{
    vec4 o = glFragColor;

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float height = GetHeight( uv );
    
    vec3 eps = vec3( 0.002, 0.002, 0.0 ); // vec3( vec2( 2.0 ) / resolution.xy, 0.0 );
    vec2 gradient = (vec2( height ) - vec2( GetHeight( uv + eps.xz ), GetHeight( uv + eps.zy ))) / eps.xy;
    
    vec3 normal = normalize( vec3( gradient * BUMP_STRENGTH, 1.0 ) );
    
    // sphere normal
    //normal = vec3( uv - vec2( 0.5, 0.5 ), 0.0 ) * 2.0;
    //normal.z = sqrt( 1.0 - dot( normal.xy, normal.xy ) );
    
    //const vec3 lightDir = normalize( vec3( -0.8, 0.5, 1.0 ) );
    //vec3 lightPos = vec3( 0.5 + 0.3 * cos( time ), 0.5 + 0.3 * sin( time ), 0.2 );
    vec3 lightPos = vec3( -0.2, 0.7, 0.4 );
    vec3 lightDir = lightPos - vec3( uv, height * BUMP_STRENGTH );
    float lightDist = length( lightDir );
    float lightAttenuation = 1.2f; // / (1.0f + lightDist * lightDist * 0.2);
    lightDir /= lightDist;
    
    //float dust = pow( texture( iChannel0, uv * 0.1 + vec2( time * 0.0015, height * -0.01 ) ).x * 1.05, 80.0 );
    float dust = Glitter( uv + vec2( time * 0.04, height * -0.02 ) );
    dust = mix( 0.0, dust, uv.x );
    
    vec3 reflectDir = vec3( 0.0, 0.0, -1.0 ) + normal * (2.0 * normal.z);
    float specPower = mix( 140.0, 10.0, min( dust, 1.0 ) );
    float spec = pow( max( dot( reflectDir, lightDir ), 0.0 ), specPower ) * lightAttenuation;
    spec = mix( spec * 2.0, spec * 5.0, dust );
    
    float diffuse = max( dot( normal, lightDir ), 0.0 ) * lightAttenuation;
    float shadow = GetUnshadowedLightFrac( uv, height, lightDir ); // pow( height, 0.5 );
    diffuse *= shadow;
    float ambientOcclusion = pow( height, 0.5 );
    const float ambient = 0.01;
    
    vec3 albedo = Color( uv.x + (height - 1.0) * 0.05 ); // texture( iChannel0, uv - vec2( 0.0, height * 0.03 ) ).xyz;
    albedo += vec3( 1.0, 0.5, 0.1 ) * dust;
    
    vec3 color = albedo * (diffuse + ambient * ambientOcclusion);
    color += spec * shadow * vec3( 1.3, 1.0, 0.7 );
    //color += vec3( 1.0, 0.3, 0.1 ) * 0.1 * dust;
    
    /*float skyReflectAmount = max( reflectDir.z, 0.0 );
    vec2 skyPos = reflectDir.xy / reflectDir.z * 0.02 * vec2( -1.0, 1.0 );
    //skyPos = uv;
    vec3 skyColor = texture( iChannel0, skyPos ).yzx;
    //skycolor = pow( skyColor, vec3( 7.0, 10.0, 5.0 ) );
    skyColor = pow( skyColor * 1.3, vec3( 7.0, 10.0, 5.0 ) * 1.5 );
    color += skyColor * skyReflectAmount * 0.5;*/
    
    vec3 refractDir = refract( vec3( 0.0, 0.0, -1.0 ), normal, 0.95 );
    /*float refractAmount = pow( max( -refractDir.z, 0.0 ), 3.0 );
    refractDir /= -refractDir.z;
    vec3 groundColor = texture( iChannel0, refractDir.xy * 0.1 ).xyz;
    //color += albedo * groundColor * refractAmount * (1.0 - diffuse);
    color += groundColor.x * refractAmount * (1.0 - diffuse) * vec3( 0.1, 0.2, 0.6 ) * 0.2;*/
    
    //color = refractDir * 0.5 + 0.5;
    //if ( refractDir.x < 0.0 )
    //    color += pow( -refractDir.x, 1.0 );
    
    const float GroundZ = -1.0;
    // intersect refractDir with z = GroundZ plane
    vec2 groundPos = uv + refractDir.xy * GroundZ / refractDir.z;
    // find light ray intersect with z = 0
    vec3 groundLightDir = vec3( -0.2, 0.2, 1.0 ); // lightPos - vec3( groundPos, GroundZ );
    vec2 groundShadowPos = groundPos + groundLightDir.xy * (-GroundZ / groundLightDir.z);
    float groundBrightness = pow( GetHeight( groundShadowPos ), 10.0 );
    vec3 groundColor = vec3(0.0); //pow( texture( iChannel0, groundPos ).xzy, vec3( 5.0 ) ) * vec3( 0.6, 0.3, 0.5 ) * 0.5;
    color += mix( vec3( 0.0 ), groundColor, uv.x ) * groundBrightness;
    
    o = vec4( color, 1.0 );
    
    //o = vec4( vec3( height ), 1.0 );
    
    #if DEBUG_MAX_GRADIENT
        o = vec4( vec3( pow( length( gradient.xy ) / MAX_GRADIENT, 100.0 ) ), 1.0 );
    #endif
    
    o = sqrt( o ); // totally accurate gamma correction

    glFragColor = o;
}
