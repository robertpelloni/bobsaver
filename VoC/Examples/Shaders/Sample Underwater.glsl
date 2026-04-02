#version 420

// original https://www.shadertoy.com/view/WdByRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdCylinder(vec3 p, float r, float h)
{
    return max(length(p.xz) -r, abs(p.y) - h);
}

float hash( float n )
{
    return fract(sin(n) * 43758.5453);
}

//Hash from iq
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 k = fract(x);
    k = k*k*(3.0-2.0*k);
    
    float n = p.x + p.y * 57.0 + p.z * 113.0;
    float a = hash(n);
    float b = hash(n + 1.0);
    float c = hash(n + 57.0);
    float d = hash(n + 58.0);

    float e = hash(n + 113.0);
    float f = hash(n + 114.0);
    float g = hash(n + 170.0);
    float h = hash(n + 171.0);
    
    float res = mix(mix(mix(a, b, k.x), mix(c, d, k.x), k.y),
                    mix(mix(e, f, k.x), mix(g, h, k.x), k.y),
                k.z);
    return res;                
}
#define rotate(ang) mat2(cos(ang), sin(ang), -sin(ang), cos(ang))
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float map(vec3 p)
{
    vec3 rp = p;
    vec2 id = floor(rp.xz / 20.0);
    rp.xz = mod(rp.xz, 20.0) - 10.0;
    float d = sdCylinder(rp + vec3(hash(id.x) * 20.0 - 10.0, 0.0, hash(id.y) * 20.0 - 10.), 2.0, 50.);
    float ground = noise(p * 0.5) + noise(p) * 0.5 + noise(p * 2.0) * 0.25;
    d = smin(d, p.y + 10.0, 5.0);
    return d - ground;
}

vec3 norm(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float caustic(vec3 p)
{
    return abs(noise(p + mod(time, 40.0) * 2.0) - noise(p + vec3(4.0, 0.0, 4.0) + mod(time,40.0) * 2.0));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 r0 = vec3(20.0, 10.0, -20.0);
    r0.xz *= rotate(0.58);

    vec3 ww = normalize(-r0);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));

    vec3 rd = normalize(uu * uv.x + vv * uv.y + ww);

    float d = 0.0;
    for(int i = 0; i < 100; ++i)
    {
        vec3 p = r0 + d * rd;
        float t = map(p);
        d += t;
        if(d > 100.0 || t < 0.001) break;
    }
    vec3 col = vec3(0.0);
    vec3 p = r0 + d * rd;
    if(d < 100.0)
    {
        vec3 n = norm(p);
        vec3 ld = normalize(vec3(0.5, 1.0, -0.5));
        float diff = max(dot(n, ld), 0.0);
        col += diff * vec3(0.6, 0.8, 1.0);
        col += (n.y * 0.5 + 0.5) * vec3(0.16, 0.20, 0.28);
        float n1 = noise(p * 0.5);
        float n2 = noise(p);
        float n3 = noise(p * 8.);
        col *= n1 * vec3(0.2, 1.0, 0.1) * 2.0 + n2 * vec3(2.0, 0.2, 0.1) * 2.0 + n3 * vec3(0.5, 0.5, 0.1);
    }
    
    col += smoothstep(0.0, 1.0, (1.0 - caustic(p * 0.5)) * 0.5);
    float fog = clamp(exp(-d * 0.035), 0.0, 1.0);
    col = mix(col, vec3(0.2, 0.5, 1.0), 1.0 - fog);
    col = pow(col, vec3(0.4545));
    
    glFragColor = vec4(col, 1.0);
}
