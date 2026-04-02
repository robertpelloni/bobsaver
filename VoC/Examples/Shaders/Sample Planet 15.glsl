#version 420

// original https://www.shadertoy.com/view/3lBXWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash2d( in vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

// return gradient noise (in x) and its derivatives (in yz)
vec3 noise2dd( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);
    
    vec2 ga = hash2d( i + vec2(0.0,0.0) );
    vec2 gb = hash2d( i + vec2(1.0,0.0) );
    vec2 gc = hash2d( i + vec2(0.0,1.0) );
    vec2 gd = hash2d( i + vec2(1.0,1.0) );
    
    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

vec3 fbm2dd(vec2 p)
{
    float w = 0.66;
    vec3 acc = vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < 6; ++i)
    {
        acc += noise2dd(p) * w;
        w *= 0.5;
        p *= 2.0;
    }
    return acc;
}

float length2(vec2 p) { return dot(p, p); }

float worley(vec2 p) {
    float d = 1e30;
    for (int xo = -1; xo <= 1; ++xo)
    for (int yo = -1; yo <= 1; ++yo) {
        vec2 tp = floor(p) + vec2(xo, yo);
        d = min(d, length2(p - tp - hash2d(tp)));
    }
    return 3.*pow(2.718, -4.*abs(2.*d - 1.));
}

float fworley(vec2 p) {
    float off = 2.5;
    float r = 1.0;
    for (int i = 0; i < 6; ++i)
    {
        r *= worley(p + off);
        p *= 2.0;
        off *= 0.5;
        off += 1.173;
    }
    return sqrt(sqrt(sqrt(r)));
}

float gain(float x, float k) 
{
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}

vec3 gainv(vec3 x, float k)
{
    return vec3(gain(x.x, k), gain(x.y, k), gain(x.z, k));
}

vec3 lerpv(vec3 x, vec3 y, float t)
{
    return mix(x, y, t);
}

float saturate(float x)
{
    return clamp(x, 0.0, 1.0);
}

vec3 col(float x, float y)
{
    float xt = (x - 0.5) * 2.0;
    float yt = (y - 0.5) * 2.0;
    vec3 ro = vec3(0.0, 0.0, 2.5);
    vec3 rd = normalize(vec3(xt, yt, -2.0));
    float b = dot(ro, rd);
    float c = dot(ro, ro) - 1.0;
    float h = b * b - c;
    if (h > 0.0)
    {
        float t = -b - sqrt(h);
        vec3 pos = ro + rd * t;
        vec3 n = pos;
        float dif = max(n.x * 2.0 + n.z, 0.0);
        float zlus1 = n.z + 1.0;
        vec2 nc = ((n.xy / zlus1) + vec2(1.0, 1.0)) * 3.0;
        vec3 nois = fbm2dd(nc);
        float wateramt = 0.5;
        float wateramtv = 2.0 * wateramt - 1.0;
        float albt = smoothstep(wateramtv, wateramtv + 0.01, nois.x);
        float nv = saturate(nois.x);
        vec3 alb = lerpv(vec3(0.05, 0.27, 0.44), lerpv(vec3(0.4, 0.45, 0.35), vec3(0.3, 0.2, 0.1), nv), albt);
        float spe = saturate(dot(n, normalize(vec3(0.4, -0.3, 1.0))));
        float spev = pow(spe, 64.0) * (1.0 - albt);
        float fwor = fworley(nc);
        float city = pow(fwor, 2.5);
        float cityamt = smoothstep(0.0, dif, 0.2) * albt;
        vec3 emm = max(vec3(city * vec3(1.8, 1.8*city, 0.5)), 0.0);
        
        float cloud = gain(smoothstep(-0.15, 0.3, fbm2dd(nc + vec2(3.7, 9.6)).x), 1.5);
        vec3 albc = lerpv(alb, vec3(1.2), cloud);
        vec3 lit = albc * (0.08 + dif * 0.75) + spev + emm * cityamt;
        float fre = 1.0-clamp(n.z,0.0,1.0);
        lit += mix( vec3(0.20,0.10,0.05), vec3(0.4,0.7,1.0), dif )*0.2*fre;
        lit += mix( vec3(0.02,0.10,0.20), vec3(0.7,0.9,1.0), dif )*fre*fre*fre;
        
        return lit;
    }
    else
    {
        return vec3(0.1, 0.1, 0.1);
    }
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;

    // Output to screen
    glFragColor = vec4(col(uv.x, 1.0 - uv.y), 1.0);
}
