#version 420

// original https://www.shadertoy.com/view/mtBcDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Noise Splash Zoom
// by Leon Denise
// 2023/08/19

#define R resolution.xy
#define ss(a,b,t) smoothstep(a,b,t)
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }

float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 5; ++i, a /= 2.) {
        seed.z += result*.5;
        result += abs(gyroid(seed/a)*a);
    }
    return result;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-R/2.)/R.y;
    float d = length(p);
    p = normalize(p) * log(length(p)*.5);
    p = vec2(atan(p.y, p.x), length(p)*.5+time*.5);
    float shades = 6.;
    float shape = ss(.9, .5, fbm(vec3(p*.5, 0.)));
    float shade = ceil(shape*shades)/shades;
    vec3 color = vec3(shade)*ss(2., .0, d);
    glFragColor = vec4(color,1.0);
}
