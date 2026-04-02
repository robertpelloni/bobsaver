#version 420

// original https://www.shadertoy.com/view/XlKfWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define    TAU 6.28318

float pMod1(inout float p, float size)
{
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float hash(vec2 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return fract( p.x*p.y*(p.x+p.y) );
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// out: 0->val->0
float SmoothTri2(float t, float val)
{
    return val * (1.0-(0.5+cos(t*TAU)*0.5));
}

mat2 rotate(float a)
{
    float c = cos(a),
        s = sin(a);
    return mat2(c, s, -s, c);
}

float objID = 0.0;
float svobjID = 0.0;

float map(vec3 p)
{
    p.xy *= rotate(p.z * .08 + time * .34);
    float c1 = pMod1(p.z,44.0);
    
    float dist = 3.5 -abs(p.y);
    
    vec3 p2 = p;
    float cz = pMod1(p2.z,4.0);
    float cx = pMod1(p2.x,4.0);
    float r = hash(vec2(cz+(cz*0.31),cx+(cx*0.61)));

    if (abs(cx)<1.0)
        r=0.0;

    if (r>0.55)
    {
        float d2 = sdCylinder(p2,vec2(0.5,5.5));         
        dist = smin(dist,d2,1.0);
    }

    objID = abs(p.z)/44.0;
    return dist;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.001, 0.);
    vec3 n;
    n.x = map(p + e.xyy) - map(p - e.xyy);
    n.y = map(p + e.yxy) - map(p - e.yxy);
    n.z = map(p + e.yyx) - map(p - e.yyx);
    return normalize(n);
}

vec3 render(vec2 uv)
{
    vec3 ro = vec3(0.0,0.0, time*8.75);
    vec3 rd = normalize(vec3(uv, 1.95));
    vec3 p = vec3(0.0);
    float t = 0.;
    for (int i = 0; i < 80; i++)
    {
        p = ro + rd * t;
        float d = map(p);
        if (d < .001 || t > 100.) break;
        t += .5 * d;
    }
    
    svobjID = objID;
    vec3 l = ro+vec3(0.0,0.0,12.0);
    vec3 n = normal(p);
    vec3 lp = normalize(l - p);
    float diff = 1.2 * max(dot(lp, n), 0.);
    
    vec3 c1 = vec3(2.54,2.2,1.25);
    vec3 c2 = vec3(2.54,1.1,1.85);
    
    float m = svobjID;
    vec3 col = mix(c1,c2,m);
    
    return col*diff / (1. + t * t * .01);
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = render(uv);
    // vignette
    col *= 0.4 + 0.6*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
    glFragColor = vec4(col, 1.);
}

