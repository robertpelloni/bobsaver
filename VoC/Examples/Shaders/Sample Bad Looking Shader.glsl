#version 420

// original https://www.shadertoy.com/view/Ws2GWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float caps(vec3 p, float r, float l)
{
    return length(p-vec3(0., clamp(p.y, -l, l), 0.)) - r;
}

float map(vec3 p)
{
    p.xz *= rot(time);
    //p.yz *= rot(time);
    p.x += time;
    float a = 2.5;
    p = mod(p+vec3(5.), 10.)-vec3(5.);
    
    p = abs(p);
    float d = 1000.;
    for(int i=0; i<2; ++i) {
        p.xz *= rot(a);
        p.yz *= rot(a);
        p.xy *= rot(.4*a);
        p.x += float(i)*.1;
        p.y += float(i)*float(i)*.1;
        for(int j=0; j<6; ++j) {
            p.x *= float(j);
            //p.xy *= rot(a);
            p.y += sin(p.x)*.05;
            p.x *= sin(a);
            d = min(d, max(max((caps(p, .5, .5) + .2), p.y), -caps(p, .2, .4)));
        }
    }
    
    return d;
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(int i=0; i<128; ++i) {
        float d = map(ro+rd*t);
        if(d < .001) break;
        if(t > 100.) break;
        t += d;
    }
    return t;
}

vec3 getNormal(vec3 p)
{
    vec2 eps = vec2(0.001, 0.);
    return normalize(vec3(
        map(p+eps.xyy) - map(p-eps.xyy),
        map(p+eps.yxy) - map(p-eps.yxy),
        map(p+eps.yyx) - map(p-eps.yyx)
    ));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x/resolution.y;

    // Time varying pixel color
    vec3 eye = vec3(0., 0., 5.);
    vec3 dir = normalize(vec3(uv.x, uv.y, -1.));
    float d = march(eye, dir);
    vec3 p = eye+dir*d;
    vec3 normal = getNormal(p);
    vec3 col = normal;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
