#version 420

// original https://www.shadertoy.com/view/tdlBRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Ray
{
    vec3 org;
    vec3 dir;
};

// reference: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdPlane( vec3 p, vec4 n )
{
    // n must be normalized
    return dot( p, n.xyz ) + n.w;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float opU( float d1, float d2 )
{
    return min(d1,d2);
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

vec3 translate( vec3 v, vec3 t )
{
    return v - t;
}

vec3 rotation(vec3 point, vec3 axis, float angle){
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    mat4 rot= mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,0.0,0.0,1.0);
    return (rot*vec4(point,1.)).xyz;
}

vec3 reverseProj(in vec3 p) {
    float r = dot(p.xz, p.xz);
    
    return vec3(
        p.x * (1. - (3. + r)/(9. + r)),
        (3. * (3. + r))/(9. + r),
        p.z * (1. - (3. + r)/(9. + r))
    );
}

vec3 proj(in vec3 p) {
    float yy = 3. - p.y;
    return vec3(
        p.x * (1. - p.y / yy),
        3. * p.y / yy + p.y * (1. - p.y / yy),
        p.z * (1. - p.y / yy)
    );
}

vec3 sphericalCentre(in vec3 a, in vec3 b) {
    vec3 centre = .5 * (a +  b);
    centre -= vec3(0, 2, 0);
    centre = normalize(centre);
    centre += vec3(0, 2, 0);
    return centre;
}

float makeHole(in vec2 p, in vec3 pos, in float d) {
    vec3 p1 = reverseProj(vec3(p.x, 0., p.y + 0.5));
    vec3 p2 = reverseProj(vec3(p.x, 0., p.y - 0.5));
    vec3 centre = sphericalCentre(p1, p2);
    float r = length(p1 - centre);
    float hole = sdSphere(translate(pos, centre), 0.9 * r);
    return opS(hole, d);
}

float makeCut(in vec3 p, in vec3 pos, in float d) {
    vec3 pp = reverseProj(p);
    vec3 np = vec3(0., 3., 0.);
    vec3 centre = sphericalCentre(np, pp);
    float r = length(pp - centre);
    float hole = sdSphere(translate(pos, centre), r);
    return opS(hole, d);
    
}

float scene( in vec3 pos )
{
    vec4 plane = vec4( 0.0, 1.0, 0.0, 0.0 ); // xyz, d
    float dPlane = sdPlane( pos, plane );
    
    pos -= vec3(0., 2., 0.);
    float t = mod(time, 18.);
    float theta = 0.9 * sin(2.09 * t);
    theta *= (smoothstep(6., 7., t) - smoothstep(8., 9., t));
    pos = rotation(pos, vec3(1., 0., 0.), theta);
    pos += vec3(0., 2., 0.);
    

    float sphere = sdSphere( translate( pos, vec3(0., 2., 0.)), 1. );
    float innerSphere = sdSphere( translate( pos, vec3(0., 2., 0.)), 0.99);
    
    float hole1 = sdSphere( translate( pos, vec3(0., 3., 0.)), 0.6);
    float hole2 = sdSphere( translate( pos, vec3(0., 1., 0.)), 0.6);
    
    float d =  opS(hole1, opS(innerSphere, sphere));
    float w = 3.;
    for (float i = -w; i <= w; i++) {
        for (float j = -w; j <= w; j++) {
            d = makeHole(vec2(i, j), pos, d);
        }
    }
    
    w += 0.7;
    d = makeCut(vec3(w, 0., 0.), pos, d);
    d = makeCut(vec3(-w, 0., 0.), pos, d);
    d = makeCut(vec3(0., 0., w), pos, d);
    d = makeCut(vec3(0., 0., -w), pos, d);
    
       
    return opU(dPlane, d);
}

// calculate scene normal using forward differencing
vec3 sceneNormal( vec3 pos, float d )
{
    float eps = 0.001;
    vec3 n;
    
    n.x = scene( vec3( pos.x + eps, pos.y, pos.z ) ) - d;
    n.y = scene( vec3( pos.x, pos.y + eps, pos.z ) ) - d;
    n.z = scene( vec3( pos.x, pos.y, pos.z + eps ) ) - d;
    
    return normalize(n);
}

bool raymarch( Ray ray, out vec3 hitPos, out vec3 hitNrm )
{
    const int maxSteps = 256;
    const float hitThreshold = 0.00001;

    bool hit = false;
    hitPos = ray.org;

    vec3 pos = ray.org;

    for ( int i = 0; i < maxSteps; i++ )
    {
        float d = scene( pos );

        if ( d < hitThreshold )
        {
            hit = true;
            hitPos = pos;
            hitNrm = sceneNormal( pos, d );
            break;
        }
        pos += d * ray.dir;
    }
    return hit;
}

float shadow( vec3 ro, vec3 rd, float mint, float maxt )
{
    float t = mint;
    for ( int i = 0; i < 64; ++i )
    {
        float h = scene( ro + rd * t );
        if ( h < 0.001 && i > 0) {
            return 0.2;
        }
        t += h;
        
        if ( t > maxt )
            break;
    }
    return 1.0;
}

vec3 shade( vec3 pos, vec3 nrm, vec4 light )
{
    vec3 toLight = light.xyz - pos;
    
    float toLightLen = length( toLight );
    toLight = normalize( toLight );
    
    float comb = 0.0;
       float vis = shadow( pos, toLight, 0.01, toLightLen );

    if ( vis > 0.0 )
    {
        float diff = 2.0 * max( 0.0, dot( nrm, toLight ) );
        float attn = 1.0 - pow( min( 1.0, toLightLen / light.w ), 2.0 );
        comb += diff * attn * vis;
    }
    
    return vec3( comb, comb, comb );
}

void main(void)
{
    // gl_FragCoord.xy: location (0.5, 0.5) is returned 
    // for the lower-left-most pixel in a window
    
    // XY of the normalized device coordinate
    // ranged from [-1, 1]
    float t = time;
    t = mod(t, 18.);
    vec2 ndcXY = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    
    // aspect ratio
    float aspectRatio = resolution.x / resolution.y;
    
    // scaled XY which fits the aspect ratio
    vec2 scaledXY = ndcXY * vec2( aspectRatio, 1.0 );
    
    // camera XYZ in world space
    vec3 camWsXYZ = vec3( 0.0, 2.2, 2.0 );
    
   camWsXYZ.y -= smoothstep(3., 6., t);
    
    camWsXYZ.z += 3. * smoothstep(3., 6., t);
    camWsXYZ.y *= (1. - smoothstep(10., 12., t))
        ;
    camWsXYZ.y += 2.2 * smoothstep(13., 15., t);
    camWsXYZ.z *= (1. - smoothstep(13., 15., t));
    camWsXYZ.z += smoothstep(13., 15., t) * 2.;
    
    
    // construct the ray in world space
    Ray ray;
    ray.org = camWsXYZ;
    ray.dir =  normalize(vec3( scaledXY, -1 )); // OpenGL is right handed
    
    float theta = -0.3 + 0.7 * smoothstep(3., 6., t);
    
    theta += (1.57 - 0.4) * smoothstep(10., 12., t);
    theta *= (1. - smoothstep(13., 15., t));
    theta += smoothstep(13., 15., t) * (-0.3);
    
    ray.dir = rotation(ray.dir, vec3(1., 0., 0.), theta);
    ray.org = rotation(ray.org, vec3(1., 0., 0.), theta);
    
    theta = -0.71 + 2.28 * smoothstep(6., 9., t);
    theta -= smoothstep(13., 18., t) * 2.28;
    ray.dir = rotation(ray.dir, vec3(0., 1., 0.), theta);
    ray.org = rotation(ray.org, vec3(0., 1., 0.), theta);
    
    // define the point light in world space (XYZ, range)
    vec4 light1 = vec4( 0.0, 0., 0.0, 8.0 );
    light1.y = 7. - 4. * (
        smoothstep(0., 2.8, t)
        -  smoothstep(13., 18., t));
    
    vec4 light2 = vec4( 1.0, 2.0, 4.2, 9.0 );
    
    vec3 sceneWsPos;
    vec3 sceneWsNrm;
    
    if ( raymarch( ray, sceneWsPos, sceneWsNrm ) )
    {
        // our ray hit the scene, so shade it with 2 point lights
        vec3 shade1 = shade( sceneWsPos, sceneWsNrm, light1 );
        vec3 shade2 = shade( sceneWsPos, sceneWsNrm, light2 );
        
        vec3 shadeAll = 
              0.8 * shade1 * vec3( 0.5, 0.5, 0.8 )
            +  0.5 * shade2 * vec3( 0.5, 0.5, 1.0 );
        
        glFragColor = vec4( shadeAll, 1.0 );
    }
    else
    {
        glFragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
    }
    
    if (sceneWsPos.y < 0.01) {
        glFragColor.rgb += vec3(0.1, 0.3, 0.3);   
    }
    
    // point source of light.
    float flare = dot(normalize(ray.dir), normalize(light1.xyz - ray.org));
    glFragColor += 0.6 * smoothstep(0.999, 1., pow(flare, 2.));
    glFragColor += 0.4 * smoothstep(0.97, 0.9999, pow(flare, 0.5));
    
    
}
