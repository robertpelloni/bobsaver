#version 420

// original https://www.shadertoy.com/view/XlfGD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 4.
#define SC 1.05
#define BG vec3(.15, .20, .25)
#define S0 vec3(1)
#define S1 vec3(0)

// 0.0 : Outside the shape
// 0.5 : Inside the shape, dark area
// 1.0 : Inside the shape, light area
float yingyang(vec2 p)
{
    vec4 d = vec4(0., .125, .5, 1.);    
    
    float c = step(
                  step(length(p + d.xz), d.z)
                - step(length(p - d.xz), d.z)
                + step(p.x, d.x),
            d.z);
    
    float b = c                                     // Curve
            + step(length(p + d.xz) / d.y, d.w)  // Dot top
            - step(length(p - d.xz) / d.y, d.w); // Dot bottom    
    
    return step(length(p), d.w) > d.x // Circle boundaries
        ? d.z * (d.w + step(b, d.x)) 
        : d.x;
}

vec3 sample(vec2 p)
{
    float c = yingyang(p);    
    if      (c > .75) return S0;
    else if (c > .25) return S1;    
    return BG;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy * 2. - 1.)
            * vec2(resolution.x / resolution.y, 1.)
            * SC;
    
    vec3 c = vec3(0);
    
#ifdef AA
    // Antialiasing via supersampling
    float e = 1. / min(resolution.y , resolution.x);    
    for (float i = -AA; i < AA; ++i) {
        for (float j = -AA; j < AA; ++j) {
            c += sample(uv + vec2(i, j) * (e/AA)) / (4.*AA*AA);
        }
    }
#else
    c = sample(uv);

#endif /* AA */
    
    glFragColor = vec4(c, 1);
}
