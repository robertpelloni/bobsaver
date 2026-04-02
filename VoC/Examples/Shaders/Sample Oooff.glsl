#version 420

// original https://www.shadertoy.com/view/wd33DH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat3 rot(vec3 angles)
{   
    float theta = angles.y;
    float c = cos(theta);
    float s = sin(theta);
    mat3 m = mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
    
    theta = angles.x;
    c = cos(theta);
    s = sin(theta);
    m *= mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
    
    theta = angles.z;
    c = cos(theta);
    s = sin(theta);
    m *= mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
    
    return m;
}

vec3 warp(vec3 p)
{
    mat3 m = rot((floor((p + 4.) / 8.) + vec3(0., -1., 0.)) * time);
    
    vec3 rep = mod(p + vec3(4.), 8.) - vec3(4.);
    return m * rep;
}

float sdf(vec3 p)
{
    p = warp(p);
    float h2 = 1.;
    float r = 1.;
    float inflate = .5;
    
    float capDist = max(abs(p.y) - h2, 0.);
    float sideDist = max(length(p.xz) - r, 0.);
    return sqrt(pow(sideDist, 2.) + pow(capDist, 2.)) - inflate;
}

float eyeSDF(vec3 p, vec2 eyePos)
{
    return length(vec2(2, 1) * (p.xy - eyePos)) - .2;
}

float mouthSDF(vec3 p)
{
    float thickness = .05;
    
    float ringDist = max(abs(length(p.xy * vec2(1.6, 1)) - 1.) - thickness, 0.);
    float hideFactor = max(p.y + .4, 0.);
    
    
    return ringDist + hideFactor;
}

vec3 albedoSDF(vec3 p)
{
    p = warp(p);
    float eyeDist = min(eyeSDF(p, vec2(.33, .7)), eyeSDF(p, vec2(-.33, .7)));
    eyeDist = min(eyeDist, mouthSDF(p));
    
    float factor = clamp(eyeDist * 10., 0., 1.);
    if (p.z < 0.)
        factor = 1.;
    
    return mix(vec3(0.05, 0.05, 0.1), vec3(1., .85, .2), factor);
}

vec3 nsdf(vec3 p)
{
    vec2 H = vec2(0., 0.01);
    return normalize(vec3(sdf(p + H.yxx), sdf(p + H.xyx), sdf(p + H.xxy)) - sdf(p));
}

vec3 lighting(vec3 albedo, vec3 n)
{
    float NL = max(dot(n, vec3(1., 1., 1.)), 0.) * .8;
    return (NL + .1) * albedo;
}

mat3 view()
{
    return rot(.02 * vec3(sin(time * .5672), sin(time * .1414), sin(time * 0.114) * 0.2));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    vec3 O = vec3(0., mod(-time * 20., 64.) * 0., 5.);
    vec3 D = view() * normalize(vec3(uv.x, uv.y, -1.));
    
    float l = 0.0;
    vec3 p;
    float d;
    for (int i = 0; i < 100; i++)
    {
        p = O + D * l;
        d = sdf(p);
        l += d;
    }
    
    vec3 n = nsdf(p);
    vec3 albedo = albedoSDF(p);
    
    if (d > .01)
        glFragColor = vec4(0.);
    else
        glFragColor = vec4(lighting(albedo, n), 1.0);
    
    float fogFactor = clamp(l / 100., 0., 1.);
    glFragColor = mix(glFragColor, vec4(0.), fogFactor);
}
