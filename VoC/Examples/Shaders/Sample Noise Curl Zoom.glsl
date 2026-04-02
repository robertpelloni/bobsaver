#version 420

// original https://www.shadertoy.com/view/mlXBzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Noise Curl Zoom
// by Leon Denise
// 2023/08/20

#define R resolution.xy
#define ss(a,b,t) smoothstep(a,b,t)
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm (vec2 pos)
{
    vec3 p = vec3(pos, 0.);
    float result = 0., a = .5;
    for (int i = 0; i < 5; ++i, a /= 2.) {
        p.z += result*.5;
        result += gyroid(p/a)*a;
    }
    return result;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-R/2.)/R.y;
    
    // polar coordinates with scrolling log radius
    p = vec2(atan(p.y, p.x), log(length(p))-time*.3);
    
    // curl noise
    vec2 e = vec2(.001,0);
    float x = (fbm(p+e.yx)-fbm(p-e.yx))/(2.*e.x);
    float y = (fbm(p+e.xy)-fbm(p-e.xy))/(2.*e.x);
    vec2 curl = vec2(x,-y);
    
    // shape from curl noise magnitude
    float d = length(curl);
    float px = fwidth(d); // AA by Fabrice Neyret
    glFragColor = vec4(ss(-px,px,d-2.5));
}
