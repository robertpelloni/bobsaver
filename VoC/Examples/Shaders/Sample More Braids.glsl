#version 420

// original https://www.shadertoy.com/view/4ttcRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.1415926535;
const float pi23 = pi*2./3.;
const float bc = 20./3.;

void main(void)
{
    float pixel = 4./min(resolution.x, resolution.y);
    vec2 uv = pixel * (gl_FragCoord.xy - .5*resolution.xy);
    vec2 pol = vec2(length(uv), atan(uv.x, uv.y));
    float th = pol.y*bc;
    vec3 sn = sin(vec3(th, th + pi23, th - pi23));
    vec3 waves = 1.5 + sn*(1./6.);
    vec3 width = .01*(6. - sn*sn) * (cos(pol.y + time*pi*.5) + 2.55);
    vec3 dists = abs(pol.x - waves);
    vec3 braid = smoothstep(width + pixel, width - pixel, dists) 
        *smoothstep(1.1*width - pixel, 1.1*width + pixel, dists).yzx;
    vec3 col = vec3(max(max(braid.x, braid.y), braid.z));
    glFragColor = vec4(col,1);
}
