#version 420

// original https://www.shadertoy.com/view/4tdczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.1415926535;
const float tau = 2.*pi;
const float halfpi = pi/2.;
const float pi23 = pi*2./3.;

vec3 hue(float theta){
    return clamp(0.5+sin(vec3(theta+pi23, theta, theta-pi23)), 0., 1.);
}
void main(void)
{
    float pixel = 6./min(resolution.x, resolution.y);
    vec2 uv = pixel * (gl_FragCoord.xy - 0.5*resolution.xy)-vec2(0.,1.);
    vec2 pol = vec2(length(uv), atan(uv.x*9., uv.y));
    vec3 col = vec3(0.);
    float aa = pixel;
    float t = time*tau/3.;
    float pcos = cos(pol.y);
    float w = 0.01/(1.1+pcos);
    float s = 0.01/(1.+pcos);
    float bc = 40.;
    float th = pol.y*bc;
    vec3 bsin = sin(vec3(th, th+pi23, th-pi23)-t);
    vec3 sins = 3.4/(2.+pcos)+bsin/6.;
    vec3 coss = 12.-bsin*bsin*2.; // -sin(x)*sin(x)*2. == -1. + cos(2.*x)
    vec3 dists = vec3(
        distance(pol, vec2(sins.x, pol.y)),
        distance(pol, vec2(sins.y, pol.y)),
        distance(pol, vec2(sins.z, pol.y))
    );
    vec3 braid = smoothstep(w*coss+aa, w*coss-aa, dists)*smoothstep(s*coss-aa, s*coss+aa, dists).yzx;
    vec3 c = hue((pol.y-t/bc)/3.);
    col += mat3(c, c.gbr, c.brg)*braid;
    if (all(equal(col, col.brg))) // mostly gets rid of an artifact at pol.y == pi
        col = vec3(0.);

    glFragColor = vec4(col,1.0);
}
