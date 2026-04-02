#version 420

// original https://www.shadertoy.com/view/tstSzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS        0.01
#define PRECISION  .7
#define ITERATIONS 120

#define COLORA (vec3(151, 203, 169) / 255.)
#define COLORB (vec3(254, 255, 223) / 255.)
#define COLORC (.3*vec3(102, 139, 164) / 255.)
#define COLORD (.1*vec3(102, 139, 164) / 255.)

float KIFS( vec3 p, float t )
{
    float scale = 1.;
    for( int i = 0; i < 12;  ++i )
    {
        vec3 n = normalize(vec3(cos(t), sin(1.1*t), 0));
        p -= n*2.*min(0.,dot(n, p));
        p.x -= .2;
        vec3 n1 = normalize(vec3(1, cos(1.7*t), sin(1.3*t)));
        p -= n1*2.*max(0.,dot(n1, p));
        p = abs(p);    
        p *= 2.;
        scale *= 2.;
        p -= vec3( 2., 2., 2. );
    }    
    return (length(p-vec3(1.,.5,1.1))-.5) / scale;
}

vec3 getOffset( vec3 coord )
{
    float lookup = 91.*coord.x + 11.*coord.y + 31.*coord.z;
    return .5*vec3(
        sin(149.*lookup+97.),
        sin(177.*lookup+13.),
        sin(457.*lookup+11.)
    );
}

vec4 map( vec3 p )
{
    const float c = 5.;
    vec3 coord = floor((p + c)/(2.*c));
    p += getOffset(coord);
    
    vec3 q = mod( p + c, 2.*c ) - c;
    vec3 flipper = (2.*mod(coord,2.)) - 1.;
    q.x *= -flipper.x;
    
    float t = .2*(time + dot(flipper, vec3(1)));
    return vec4( flipper, KIFS( q, t ));
}

struct March
{
    vec3 pos;
    float dist;
    vec3 coord;
    float ao;
};

March march( vec3 ro, vec3 rd )
{
    vec4 dist;
    float totalDist = 0.0;
    
    int i;
    for( i = 0; i < ITERATIONS; ++i )
    {
        dist = map( ro );
        if( dist.w < EPS || totalDist > 200. ) break;
        totalDist += PRECISION * dist.w;
        ro += PRECISION * rd * dist.w;
    }
    
    return March( ro, dist.w < EPS ? totalDist : -1.0, dist.xyz, float(i) / 90. );
}

mat2 rot( float theta )
{
    float c = cos( theta );
    float s = sin( theta );
    return mat2( c, s, -s, c );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    
    vec3 ro = vec3(3.*time,5.,5.*time);
    vec3 rd = normalize(vec3(uv, 1));
    
    rd.xy *= rot( .11*time );
    rd.yz *= rot( .07*time );
    rd.zx *= rot( .05*time );
    
    March m = march( ro, rd );
    
    float lightness = 0.;
    vec3 hitColor;
    
    if( m.dist >= 0.0 ) {
        float fog = exp( -.02*m.dist );
        lightness = fog * (1. - m.ao);
        
        if (m.coord.z > 0.) {
            if (m.coord.x == m.coord.y) hitColor = COLORA; else hitColor = COLORB;
        } else {
            if (m.coord.x == m.coord.y) hitColor = COLORB; else hitColor = COLORA;
        }
        
        vec3 shadow = mix(COLORD, COLORC, 1. - fog);
        hitColor = mix( shadow, hitColor, lightness );
        
    } else {
        hitColor = COLORC;
    }

    glFragColor = vec4(hitColor,1);
}
