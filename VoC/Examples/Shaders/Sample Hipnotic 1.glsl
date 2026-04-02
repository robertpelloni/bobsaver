#version 420

// original https://www.shadertoy.com/view/4s3Sz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI (3.1415)

float map(vec3 p)
{
    vec3 q = fract(p) * 2.0 -1.0;
    
    return length(q) - 0.25;
}

float trace(vec3 o, vec3 r)
{
    float t = .0;
    for (int i = 0; i < 32; ++i) {
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.3;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv = uv * (resolution.x / resolution.y); // notre environement
    
    vec3 r = normalize(vec3(uv, sin(time / 10.) /*1.*/)); // <== camera
    vec3 o = vec3(time / 2., time, time); // <== direction
    
    float rotate = time;
    r.xy *= mat2(cos(rotate), 
                 sin(rotate), 
                 -sin(rotate),
                 cos(rotate));
    r.xz *= mat2(cos(rotate), 
                 sin(rotate), 
                 -sin(rotate),
                 cos(rotate));
    float t = trace(o, r); // <== rendu
    float fog = 1. / (.0 + t * t * 0.1); // <== pour le fun
    
    vec3 fc = vec3(sin(time) * fog,
                   sin(time - (2.0/3.0 * M_PI)) * fog,
                   sin(time - (4.0/3.0 + M_PI)) * fog);
    // <== la couleur
    
    glFragColor = vec4(fc,1.0);
}
