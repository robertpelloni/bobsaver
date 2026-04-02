#version 420

// original https://www.shadertoy.com/view/wsj3Wc

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

float heart(vec2 p)
{
    p.x = abs(p.x);
    p.y *= 1.5;
    p.x *= 1.2;
    p.y -= p.x;
    float c =(length(p) - .3);
    return c / 2.;
}

float map(vec3 p)
{
    p.z -= time;
    vec3 cell = floor(p*.5);
    p.y += sin(cell.z);
    p.xy *= rot(cell.z+time*.01);
    p.xy *= rot(time*.08);
    p = mod(p, 2.)-vec3(.8);
    
    float ay = abs(p.z) - .01;
    float h = max(sqrt(pow(heart(p.xy)+.2, 2.) + pow(p.z, 2.)) - .2, ay);
    
    return h;
}

float march(vec3 ro, vec3 rd)
{
    float t = 0.;
    for(int i=0; i<128; ++i)
    {
        float d = map(ro+rd*t);
        if(d < .001+t*.03) break;
        if(t > 30.) return -1.;
        t += d*.6;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(.5);
    uv.x *= resolution.x/resolution.y;

    vec3 cam = vec3(0, 0, 3.);
    vec3 dir = normalize(vec3(uv.x, uv.y, -1.));
    float d = march(cam, dir);
    float h = heart(uv);
    vec3 col;
    
    if(d < 0.) {
        col = vec3(1., .6, .85);
    } else {
        col = vec3(clamp(d*.05, .6, 1.));
        col *= vec3(1., .3, .35) * clamp(d, 5., 100.) *.2;
           col.gb = pow(col.gb, vec2(1.4, 1.));
    }
    
    glFragColor = vec4(sqrt(col),1.0);
}
