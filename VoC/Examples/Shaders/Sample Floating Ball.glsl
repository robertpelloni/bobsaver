#version 420

// by @memorystomp
//
// big help from:
//  http://www.humus.name/index.php?page=3D&ID=42
//  and https://www.shadertoy.com/view/XdsGDB
//  and http://madebyevan.com/webgl-water/
//
// Lots of other helper functions (mostly from iq) have a URL at their
//  point of usage.  Hopefully I didn't forget any.
//
// Has only been tested on Mac & Chrome

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const vec3 eyePos = vec3(0.0, 8.2, -8.95);
const vec3 atPos = vec3( 0.0, 7.64, -8.12 );
const vec3 upDir = vec3( 0.0, 1.0, 0.0 );
const vec2 heightMapResolution = vec2( 200.0, 200.0 );

vec3 calculateCameraDir( vec2 pixel )
{
    // cobbled together from http://stackoverflow.com/questions/349050/calculating-a-lookat-matrix
    // and a few examples like http://glsl.heroku.com/e#2064.0
    vec3 ZAxis = normalize( atPos - eyePos );
    vec3 XAxis = normalize( cross( upDir, ZAxis ) );
    vec3 YAxis = cross( ZAxis, XAxis );

    vec2 uv = (pixel / resolution) - 0.5;    
    uv.y *= resolution.y / resolution.x;
    
    vec3 rayDir = normalize( ZAxis + uv.x*XAxis + uv.y * YAxis );
    
    return rayDir;
}

float getHeightMap( vec2 pixel )
{
    if( pixel.x < 0.0 || pixel.y < 0.0 || pixel.x >= heightMapResolution.x || pixel.y >= heightMapResolution.y )
    {
        return 0.8;
    }
    // 0.4 offset is for NVidia cards.  I haven't tested it yet, but it was required for Flappy Shader
    vec2 uv = (pixel + vec2(0.4,0.4)) / resolution.xy;
    return texture2D( backbuffer, uv ).a * 2.0 - 1.0;
}

float getVelocityMap( vec2 pixel )
{
    if( pixel.x < 0.0 || pixel.y < 0.0 || pixel.x >= heightMapResolution.x || pixel.y >= heightMapResolution.y )
    {
        return 0.0;
    }

    pixel.x += heightMapResolution.x;
    vec2 uv = (pixel + vec2(0.4,0.4)) / resolution.xy;
    return texture2D( backbuffer, uv ).a * 2.0 - 1.0;
}

float sampleHeight( vec3 pos )
{
    // bring to 0 to 1
    vec2 uv = (pos.xz + 5.0) / 10.0;
    
#if 0   //testing point sampling
    uv = floor( uv * heightMapResolution.xy ) / resolution.xy;

    float h = texture2D( backbuffer, uv ).a * 2.0 - 1.0;
#else
    
    vec2 whole = floor( uv * heightMapResolution.xy );
    vec2 percent = fract( uv * heightMapResolution.xy );
    
    vec4 samples = vec4(  texture2D( backbuffer, (whole) / resolution.xy ).a,
                        texture2D( backbuffer, (whole + vec2(1.0,0.0)) / resolution.xy ).a,
                        texture2D( backbuffer, (whole + vec2(0.0,1.0)) / resolution.xy ).a,
                        texture2D( backbuffer, (whole + vec2(1.0,1.0)) / resolution.xy ).a );
    
    samples.xy = mix( samples.xz, samples.yw, percent.x );
    float h = mix( samples.x, samples.y, percent.y ) * 2.0 - 1.0;
#endif
    return h * 0.4;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( vec3 pos, vec3 extents )
{
    vec3 di = abs(pos) - extents;
    float mc = max( di.x, max( di.y, di.z ) );
    return min( mc, length( max(di,0.0) ) );
}

float sdSphere( vec3 pos, float radius )
{
    return( length( pos ) - radius);
}

float getDistWater( vec3 pos )
{
    pos.y -= sampleHeight(pos);   
    vec3 extents = vec3( 4.8, 2.5, 4.8 );
    return sdBox( pos, extents );
}

// return distance and an id
vec2 getDistWorld( vec3 pos, vec3 ballPos )
{
    float ballDist = sdSphere( pos - ballPos, 0.5 );
    
    float poolDist = sdBox( pos - vec3( 0.0, -2.25, 0.0 ), vec3( 5.0, 0.2, 5.0 ) );   
    poolDist = min( poolDist, sdBox( pos - vec3( 0.0, 0.25, 4.75 ), vec3( 5.0, 2.75, 0.25 ) ) );
    poolDist = min( poolDist, sdBox( pos - vec3( 0.0, 0.25, -4.75 ), vec3( 5.0, 2.75, 0.25 ) ) );
    poolDist = min( poolDist, sdBox( pos - vec3( 4.75, 0.25, 0.0 ), vec3( 0.25, 2.75, 4.75 ) ) );
    poolDist = min( poolDist, sdBox( pos - vec3( -4.75, 0.25, 0.0 ), vec3( 0.25, 2.75, 4.75 ) ) );
    
    if( ballDist < poolDist )
    {
        return vec2( ballDist, 0.0 );
    }
    
    return vec2( poolDist, 1.0 );
}

vec3 getWorldColour( vec3 pos, float id, vec3 ballPos )
{
    if( id == 0.0 )
    {
        vec3 normal = pos - ballPos;
        float angle = atan( normal.x, normal.z ) / ( 2.0 * 3.14159 );
        
        float b = mod( angle, 0.25 ) > 0.125 ? 1.0 : 0.0;
        
        return vec3(1.0,mix(0.5,1.0,b),0.0);
    }
    
    float b = fract( sin( dot( floor(pos), vec3( 141.12351, 8513.3248, 384.3124 ) ) * 314.715 ) );
    
    b = 0.6 + b * 0.2;
    
    return vec3(b*b,b*b,b);
}

float rayMarchWater( vec3 start, vec3 ray )
{
    float total_distance = 0.0;
    
    for( int i=0; i<100; ++i )
    {
        vec3 pos = start + ray * total_distance;
        float dist = getDistWater( pos );
    
        if( dist < 0.01 )
        {
            return total_distance;
        }
        total_distance += dist;
    }
    
    return 10000.0;
}

vec2 rayMarchWorld( vec3 start, vec3 ray, vec3 ballPos )
{
    float total_distance = 0.0;
    
    for( int i=0; i<100; ++i )
    {
        vec3 pos = start + ray * total_distance;
        vec2 info = getDistWorld( pos, ballPos );
    
        if( info.x < 0.01 )
        {
            return vec2( total_distance, info.y );
        }
        total_distance += info.x;
    }
    
    return vec2( 10000.0, 0.0 );
}

// http://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float softShadow( vec3 start, vec3 lightPos, vec3 ballPos )
{
    float k = 8.0;
    float maxD = length( lightPos - start );
    vec3 lightDir = normalize( lightPos - start );
    
    float res = 1.0;
    float distance = 0.05;
    for( int i=0; i<40; ++i )
    {
        vec3 pos = start + lightDir * distance;
        vec2 distInfo = getDistWorld( pos, ballPos );
        if( distInfo.x < 0.01 )
        {
            return 0.0;
        }
        
        res = min( res, k * distInfo.x / distance );

        distance += distInfo.x;
        
        if( distance > maxD )
        {
            return res;
        }
    }
    
    return res;
}

vec3 getWaterNormal( vec3 pos )
{
    vec2 eps = vec2( 0.0, 0.1 );
    vec3 norm;
    norm.x = getDistWater( pos + eps.yxx ) - getDistWater( pos - eps.yxx );
    norm.y = 0.1;
    norm.z = getDistWater( pos + eps.xxy ) - getDistWater( pos - eps.xxy );
    return normalize(norm);
}

vec3 getWorldNormal( vec3 pos, vec3 ballPos )
{
    vec2 eps = vec2( 0.0, 0.1 );
    vec3 norm;
    norm.x = getDistWorld( pos + eps.yxx, ballPos ).x - getDistWorld( pos - eps.yxx, ballPos ).x;
    norm.y = getDistWorld( pos + eps.xyx, ballPos ).x - getDistWorld( pos - eps.xyx, ballPos ).x;
    norm.z = getDistWorld( pos + eps.xxy, ballPos ).x - getDistWorld( pos - eps.xxy, ballPos ).x;
    return normalize(norm);
}

float updateVelocityMap( vec2 pixel )
{    
    float h = getHeightMap( pixel );
    float v = getVelocityMap( pixel );
  
#if 0
    // This first version based on http://www.humus.name/index.php?page=3D&ID=42
    //  but it tended to dispurse slowly for bigger heightmaps
    float diff = -h * 4.0;
    
    diff += getHeightMap( pixel + vec2( 0.0,-1.0) );
    diff += getHeightMap( pixel + vec2(-1.0,0.0) );
    diff += getHeightMap( pixel + vec2( 1.0,0.0) );
    diff += getHeightMap( pixel + vec2( 0.0,1.0) );    
#else
    float totalSurround = 0.0;
    float totalWeight = 0.0;
    
    for( float dx=-5.0;dx<=5.0; dx+=1.0 )
    {
        for( float dy=-5.0;dy<=5.0; dy+=1.0 )
        {
            float l = length( vec2(dx,dy) );
            
            float weight = ( l > 0.0 ) ? 1.0 / l : 0.0;
            totalSurround += weight * getHeightMap( pixel + vec2( dx, dy ) );
            totalWeight += weight;
        }
    }
    
    float diff = ( totalSurround / totalWeight ) - getHeightMap( pixel );
#endif

    v += diff * 0.5;
        
    v *= 0.9;
    
    return v;
}

float updateHeightMap( vec2 pixel, float v, vec3 ballPos )
{    
    float h = getHeightMap( pixel );
    
    // have to use the current frame's velocity
    h += v * 0.8;
 
    // 8-bit water height maps have a tendancy to stay static, so keep water moving :)
    h += sin( -time + pixel.x / 30.0 + pixel.y / 50.0 ) * 0.01;
   
    vec2 uv = pixel / heightMapResolution.xy;
    
    vec2 ballUV = (ballPos.xz + 5.0) / 10.0;
    h = min( h, -0.5 + length(uv - ballUV) / 0.1);
    
    return h;
}

float calculateStorage( vec3 ballPos )
{
    float ret = 0.5;
    
    float checkBit = texture2D( backbuffer, vec2(1.0,1.0) ).a;
    if( checkBit > 0.45 && checkBit < 0.55 )
    {
        vec2 pixel = mod( gl_FragCoord.xy, heightMapResolution );
        
        if( gl_FragCoord.x < heightMapResolution.x && gl_FragCoord.y < heightMapResolution.y )
        {
            float v = updateVelocityMap( pixel );
            float h = updateHeightMap( pixel, v, ballPos );
            ret = h * 0.5 + 0.5;
        }
        else if( gl_FragCoord.x >= heightMapResolution.x && gl_FragCoord.x < heightMapResolution.x + heightMapResolution.x && gl_FragCoord.y < heightMapResolution.y )
        {
            float v = updateVelocityMap( pixel );
            ret = v * 0.5 + 0.5;
        }
    }
    return ret;
}

// shoot a ray out to find where the mouse hits the water, and we'll place
//  the beach ball there.  The ball stays pretty static, mostly because I don't
//  do anything interesting here, but also because I force its position
//  in the water.  Adding other debris to the pool would be interesting.
vec3 findBallPos()
{
    vec3 rayDir = calculateCameraDir( mouse * resolution.xy );
    float distance = rayMarchWater( eyePos, rayDir );
    if( distance < 100.0 )
    {        
        vec3 pos = eyePos + rayDir * distance;
        
        if( abs(pos.x) < 4.5 && abs(pos.z) < 4.5 )
        {
            return pos;
        }
    }
    
    return vec3( -1000.0, -1000.0, -1000.0 );
}

void main()
{
    vec3 rayDir = calculateCameraDir( gl_FragCoord.xy );
    vec3 viewDir = -rayDir;

    vec3 col = vec3(0.3, 0.8, 0.9 );
    
    vec3 lightDir = normalize( vec3( 1.0, 1.0, -0.5 ) );
    
    vec3 ballPos = findBallPos();
    
    float waterDistance = rayMarchWater( eyePos, rayDir );
    vec2 worldInfo = rayMarchWorld( eyePos, rayDir, ballPos );
    
    if(( worldInfo.x < waterDistance ) && ( worldInfo.x < 1000.0 ))
    {
        vec3 worldPos = eyePos + rayDir * worldInfo.x;
        vec3 worldNormal = getWorldNormal( worldPos, ballPos );
        
        float shadow = 0.5 + 0.5 * softShadow( worldPos, worldPos + lightDir * 100.0, ballPos );
        float diffuse = dot( worldNormal, lightDir );
        col = shadow * diffuse * getWorldColour( worldPos, worldInfo.y, ballPos );
    }
    else if( waterDistance < 1000.0 )
    {        
        vec3 waterPos = eyePos + rayDir * waterDistance;
        vec3 waterNormal = getWaterNormal( waterPos );
        
        vec3 halfDir = normalize( lightDir + viewDir );
        
        // shadows were very minor here for the scene
        // float shadowSpec = softShadow( waterPos, waterPos + lightDir * 100.0, ballPos );
        float waterSpec = pow( dot( waterNormal, halfDir ), 5.0 );

        if( worldInfo.x < 1000.0 )
        {
            vec3 refractDir = refract( rayDir, waterNormal, 0.9 );
            vec2 worldInfo = rayMarchWorld( waterPos, refractDir, ballPos );
            vec3 worldPos = waterPos + refractDir * worldInfo.x;
            vec3 worldNormal = getWorldNormal( worldPos, ballPos );
            
            float worldSpec = pow( dot( worldNormal, halfDir ), 50.0 );
            float shadow = softShadow( worldPos, worldPos + lightDir * 100.0, ballPos );
 
 // I need to do more research to see if these hacked together
 //  caustics are even in the same ballpark as realistic.
 //  They do look neat on the far wall, though :p
#if 1
            vec3 lightPos = worldPos + lightDir*100.0;
            float distFromLight = rayMarchWater( lightPos, -lightDir );
            if( distFromLight < 1000.0 && shadow > 0.5 )
            {
                vec3 surfacePos = lightPos - lightDir * distFromLight;
                vec3 surfaceNormal = getWaterNormal( surfacePos );
                
                vec3 causticLightDir = refract( lightDir, -surfaceNormal, 0.9 );
                
                vec3 halfDir2 = normalize( causticLightDir + viewDir );
                worldSpec = pow( dot( surfaceNormal, halfDir2 ), 5.0 );
            }
#endif

            float worldDiffuse = ( 1.0 - worldSpec ) * dot( worldNormal, lightDir );
        
            col = shadow * vec3(worldSpec) + ( 0.5 + 0.5 * shadow ) * worldDiffuse * getWorldColour( worldPos, worldInfo.y, ballPos );
        }

        col = mix( col, vec3(1.0), waterSpec );        
    }
    
    float a = calculateStorage( ballPos );
    glFragColor = vec4( col, a );
}
