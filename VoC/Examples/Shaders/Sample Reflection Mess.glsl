#version 420

// original https://www.shadertoy.com/view/WlVXDV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rotate(angle) mat2(cos(angle), sin(angle), -sin(angle), cos(angle))

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdCylinder(vec3 p, float r)
{
    return length(p.xz) - r;
}
float sdCappedCylinder(vec3 p, float r, float h)
{
    return max(length(p.xz) - r, abs(p.y) - h);
}

float sdBox(vec3 p, vec3 b)
{
    vec3 h = abs(p) - b;
    return max(h.x, max(h.y, h.z));
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float matId = 0.0;

vec3 kifs(vec3 p)
{
    float t = time * 0.2;
    for(int i = 0; i < 3; ++i)
    {
        p = abs(p) - 0.3;
        p.xz *= rotate(0.7878 + t);
        p.yz *= rotate(1.3 + t);
        p.xy *= rotate(2.6 + t);
    }   
    return p; 
}

float map(vec3 p)
{
    /*
    float d = sdSphere(p + vec3(0.0 ,0.3, 0.0), 0.5);
    d = min(d, sdCappedCylinder(p - vec3(1.0, 0.0, -2.0), 0.5, 1.0));
    //d = min(d, p.y + 1.0);
    float d1 = sdBox(p + vec3(-2.0, 0.0, 0.0), vec3(0.5, 1.0, 0.5));
    if(d < d1)
        matId = 0.0;
    else
    {
        matId = 1.0;
        d = d1;
    }
    */
    //p.xz *= rotate(time);
    matId = 1.0;
    p = kifs(p);
    float d = sdBox(p, vec3(0.2));
    return d;
}

vec3 hash33(vec3 p)
{
    return fract(sin(p * vec3(29.244, 59.6994, 456.4939)) * 50391.2484);
}
vec3 RandomInUnitSphere(vec3 seed) 
{
    vec3 h = hash33(seed) * vec3(2.,6.28318530718,1.)-vec3(1,0,0);
    float phi = h.y;
    float r = pow(h.z, 1./3.);
    return r * vec3(sqrt(1.-h.x*h.x)*vec2(sin(phi),cos(phi)),h.x);
}

bool rayMarch(vec3 r0, vec3 rd, inout float d)
{
    d = 0.0;
    for(int i = 0; i < 100; ++i)
        {
            vec3 p = r0 + d * rd;
            float t = map(p);
            d += t;
            if(abs(t) < 0.001)
            {
                return true;
            }
            if(d > 100.0) break;
        }
    return false;
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

void main(void)
{
    vec2 luv = gl_FragCoord.xy / resolution.xy;
    vec3 final_col = vec3(0.0);
    vec2 uv = (gl_FragCoord.xy + vec2(fract(time)) - 0.5 * resolution.xy) / resolution.y;
    vec3 r0 = vec3(0.0, 3.0, -5.0);
    vec2 mouse = (mouse*resolution.xy.xy / resolution.xy) * 10.;
    r0.yz *= rotate(mouse.y);
    r0.xz *= rotate(mouse.x);
    vec3 tgt = vec3(0.0);
    vec3 ww = normalize(tgt - r0);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    
    float zoom = 1.3;
    vec3 rd = normalize(uv.x * uu + uv.y * vv + zoom * ww);
    
    float d = 0.0;
    vec3 col = vec3(1.0);
    for(int i = 0; i < 10; ++i){
        if(rayMarch(r0, rd, d))
        {
            float mat = matId;
            vec3 p = r0 + d * rd;
            vec3 n = norm(p);
            r0 = p + 0.1 * n;
            vec3 albedo = vec3(0.8, 0.5, 0.3);
            if(mat >  0.5){
                rd = reflect(rd, n);
            }
            else{
                rd = normalize(RandomInUnitSphere(r0) + n);
                albedo = vec3(0.8, 0.2, 0.3);
            }
            col *= albedo;
        }
        else{
            col *= mix(vec3(1.0), vec3(0.5, 0.7, 1.0), rd.y + 1.5);
            break;
        }
    }

    col = pow(col, vec3(0.4545));
    /*
    if(mouse*resolution.xy.z < 0.0)
    {
        vec3 color = texture(iChannel0, luv).rgb;
        float alpha = 1.0 / float(frames + 1);
        col = mix(color.rgb, col, alpha);
    }
    */

    glFragColor = vec4(col, 1.0);
}
