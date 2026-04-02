#version 420

// original https://www.shadertoy.com/view/NtKXzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (22.0/7.0)

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float smin( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

mat2 rot(float r)
{
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

float ball(vec3 p)
{
    // scale
    float scale = cos(time*3.)*0.2+1.0;
    p *= scale;   

    // twist
    float twist = sin(time*3.);
    p.xz *= rot(mix(0., p.y*6., twist));
    
    // rot cube
    p.xz *= rot(time);
    p.xy *= rot(1.);
   
    // bulge
    float bulge = cos(time*3.);
    p += bulge*(0.07*(sin(p.x*p.y*p.z*200.)*0.5+0.5));
    
    // bloat
    float bloat = sin(time*6.)*0.5+0.5;
    return mix(sdBox(p, vec3(0.4)), length(p)-0.65, bloat);
}

float map(vec3 p)
{
    vec3 c = vec3(3.);
    vec3 q = p;
    //vec3 q = mod(p+0.5*c,c)-0.5*c;
    float d = ball(q);
    return d;
}

vec2 march(vec3 ro, vec3 rd)
{
    float t = 0.;
    vec3 p = ro;
    int i = 0;
    for (; i < 100; i++)
    {
        float dist = map(p)*0.7;
        if (dist < 0.001) break;
        t += dist;
        p = ro + t * rd;
    }
    return vec2(t, i);
}

vec3 normal(vec3 p)
{
    vec2 o = vec2(0.001, 0.);
    return normalize(vec3(
        map(p + o.xyy) - map(p - o.xyy),
        map(p + o.yxy) - map(p - o.yxy),
        map(p + o.yyx) - map(p - o.yyx)
    ));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.0 * ((gl_FragCoord.xy/resolution.xy) - 0.5);
    uv.x *= resolution.x / resolution.y;
    
    vec3 col = vec3(0.);
    for (int i = 0; i < 2; i++)
    {
        for (int j = 0; j < 2; j++)
        {
            vec3 ro = vec3(0., 0., -3.);
            vec3 rd = normalize(vec3(uv + vec2(float(i)*0.5+0.25, float(j)*0.5+0.25)*0.006, 0.) - ro);

            vec2 res = march(ro, rd);
            float dist = res.x;
            float iters = res.y;

            if (dist < 10.)
            {
                col += (normal(ro + dist * rd) * 0.5 + 0.5) * 0.25;
            }
        }
    }
    
    glFragColor = vec4(col, 1.0);
}
