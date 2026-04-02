#version 420

// original https://www.shadertoy.com/view/MsG3Wy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// consts
const float EPS = 0.01;
const float OFFSET = EPS * 100.0;
const float PI = 3.14159;

// globals
const vec3 lightDir = vec3( -0.48666426339228763, 0.8111071056538127, -0.3244428422615251 );
vec3 cPos, cDir;
vec3 sPos;
float sSize;
vec3 illuminationColor;
float tempo;

struct Intersect {
    bool isHit;

    vec3 position;
    float distance;
    vec3 normal;

    int material;
    vec3 color;
};

const int CIRCUIT_MATERIAL = 0;
const int MIRROR_MATERIAL = 1;

// distance functions
vec3 onRep( vec3 p, float interval ) {

    return mod( p, interval ) - 0.5 * interval;

}

// thanks to https://www.shadertoy.com/view/MdVGRc
float MBoxDist( vec3 p ) {

  const float scale = 2.7;
  const int n = 12;
  vec4 q0 = vec4 (p, 1.);
  vec4 q = q0;

  for ( int i = 0; i < n; i++ ) {

    q.xyz = clamp( q.xyz, -1.0, 1.0 ) * 2.0 - q.xyz;
    q = q * scale / clamp( dot( q.xyz, q.xyz ), 0.5, 1.0 ) + q0;

  }

  return length( q.xyz ) / abs( q.w );

}

float sphereDist( vec3 p, vec3 c, float r ) {

    return length( p - c ) - r;

}

float sceneDist( vec3 p ) {

    return min(
        sphereDist( p, sPos, sSize ),
        MBoxDist( onRep( p, 7.0 ) )
    );

}

// color functions
vec3 hsv2rgb( vec3 c ) {

    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.www );
    return c.z * mix( K.xxx, clamp( p - K.xxx, 0.0, 1.0 ), c.y );

}

// thanks to http://glslsandbox.com/e#21290.5
vec2 circuitPattern( vec2 p ) {

    p = fract(p);
    float r = 0.123;
    float v = 0.0, g = 0.0;
    r = fract(r * 9184.928);
    float cp, d;
    
    d = p.x;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.y;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.x - 1.0;
    g += pow(clamp(3.0 - abs(d), 0.0, 1.0), 1000.0);
    d = p.y - 1.0;
    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 10000.0);
    
    const int iter = 12;
    for(int i = 0; i < iter; i ++)
    {
        cp = 0.5 + (r - 0.5) * 0.9;
        d = p.x - cp;
        g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 200.0);
        if(d > 0.0) {
            r = fract(r * 4829.013);
            p.x = (p.x - cp) / (1.0 - cp);
            v += 1.0;
        }
        else {
            r = fract(r * 1239.528);
            p.x = p.x / cp;
        }
        p = p.yx;
    }
    v /= float(iter);
    return vec2(g, v);

}

Intersect minIntersect( Intersect a, Intersect b ) {

    if ( a.distance < b.distance ) {
        return a;
    } else {
        return b;
    }

}

Intersect sceneIntersect( vec3 p ) {

    Intersect a, b;
    a.distance = sphereDist( p, sPos, sSize );
    a.material = MIRROR_MATERIAL;

    b.distance = MBoxDist( onRep( p, 7.0 ) );
    b.material = CIRCUIT_MATERIAL;

    return minIntersect( a, b );
}

vec3 getNormal( vec3 p ) {

    return normalize(vec3(
        sceneDist(p + vec3( EPS, 0.0, 0.0 ) ) - sceneDist(p + vec3( -EPS, 0.0, 0.0 ) ),
        sceneDist(p + vec3( 0.0, EPS, 0.0 ) ) - sceneDist(p + vec3( 0.0, -EPS, 0.0 ) ),
        sceneDist(p + vec3( 0.0, 0.0, EPS ) ) - sceneDist(p + vec3( 0.0, 0.0, -EPS ) )
    ));

}

float getShadow( vec3 ro, vec3 rd ) {

    float h = 0.0;
    float c = 0.0;
    float r = 1.0;
    float shadowCoef = 0.5;

    for ( float t = 0.0; t < 50.0; t++ ) {

        h = sceneDist( ro + rd * c );

        if ( h < EPS ) return shadowCoef;

        r = min( r, h * 16.0 / c );
        c += h;

    }

    return 1.0 - shadowCoef + r * shadowCoef;

}

Intersect getRayColor( vec3 origin, vec3 ray ) {

    // marching loop
    float dist;
    float depth = 0.0;
    vec3 p = origin;
    int count = 0;
    Intersect nearest;

    for ( int i = 0; i < 64; i++ ){

        dist = sceneDist( p );
        depth += dist;
        p = origin + depth * ray;

        count = i;
        if ( abs(dist) < EPS ) break;

    }

    if ( abs(dist) < EPS ) {

        nearest = sceneIntersect( p );
        nearest.position = p;
        nearest.normal = getNormal(p);
        float diffuse = clamp( dot( lightDir, nearest.normal ), 0.1, 1.0 );
        float specular = pow( clamp( dot( reflect( lightDir, nearest.normal ), ray ), 0.0, 1.0 ), 10.0 );
        //float shadow = getShadow( p + nearest.normal * OFFSET, lightDir );

        if ( nearest.material == CIRCUIT_MATERIAL ) {

            vec2 uv = p.yz;
            vec2 dg = circuitPattern(uv);

            float glow = max( sin( length( p ) - 1.8 * time ) * 2.5, 0.0 );
            if( dg.x < 1.1 ) glow = 0.0;

            nearest.color = vec3( 0.2, 0.2, 0.2 ) + illuminationColor * glow * diffuse + specular /* * max( 0.5, shadow )*/;

        } else if ( nearest.material == MIRROR_MATERIAL ) {

            nearest.color = ( 0.5 - 0.5 * cos( time * 0.2 ) * illuminationColor * diffuse + specular )/* * max( 0.5, shadow )*/;

        }

        nearest.isHit = true;

    } else {

        nearest.color = vec3(0.1);
        nearest.isHit = false;

    }

    nearest.color += clamp( sin( time * 0.2 - 0.5 * PI ) * 0.2 * depth - 0.005 * float(count), -1.0, 1.0 );
    return nearest;

}

void main(void) {

    // fragment position
    vec2 p = ( gl_FragCoord.xy * 2.0 - resolution.xy ) / min(  resolution.x,  resolution.y );

    // camera and ray
    cPos  = vec3( -0.8185093402862549, 4.509979248046875, time );
    cDir  = normalize( vec3( sin( time * 0.5 ), sin( time * 0.1 ), cos( time * 0.6 ) + 0.5 ) );
    vec3 cSide = normalize( cross( cDir, vec3( 1.0, 1.0 ,0.0 ) ) );
    vec3 cUp   = normalize( cross( cSide, cDir ) );
    float targetDepth = 1.3;
    vec3 ray = normalize( cSide * p.x + cUp * p.y + cDir * targetDepth );

    // music's tempo
    tempo = sin( 4.0 * PI * time );

    // sphere pos
    float d = 0.2 + 0.1 * cos( time * 0.5 );
    sPos = cPos + vec3( 0.0, 0.0, d );
    sSize = 0.03 + 0.005 * tempo;

    // Illumination Color
    illuminationColor = hsv2rgb( vec3( time * 0.02 + 0.6, 1.0, 1.0 ) );

    vec3 color = vec3( 0.0 );
    float alpha = 1.0;
    Intersect nearest;

    for ( int i = 0; i < 3; i++ ) {

        nearest = getRayColor( cPos, ray );

        color += alpha * nearest.color;
        alpha *= 0.99;
        ray = normalize( reflect( ray, nearest.normal ) );
        cPos = nearest.position + nearest.normal * OFFSET;

        if ( !nearest.isHit || nearest.material == CIRCUIT_MATERIAL ) break;

    }

    color += 0.2 * tempo;

    glFragColor = vec4(color, 1.0);

}
