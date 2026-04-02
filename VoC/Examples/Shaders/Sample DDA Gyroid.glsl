#version 420

// original https://www.shadertoy.com/view/XfBBRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a + vec4(0, 11, 33, 0)))
#define map(k) dot(sin(k), cos(k.yzx)) > - 1.3
#define t time * .2

void main(void) {
    vec2 u = gl_FragCoord.xy;
    vec2 r = resolution.xy;
         u = (u - r / 2.) / r.y;
    
    vec3 p, D = normalize(vec3(u, 1)),
         side, mask, norm, k, q;
    
    float d, i, h, res = .5;
    
    // camera
    D.xz *= rot(sin(t * 3.));
    D.yz *= rot(cos(t * 2.) * 3.14);
    p = vec3(3.1, 0, t * 13. + cos(t * 1.2) * 20.);    
    
    // grid
    k = floor(p) + .5,
    side = .5 / abs(D) - (fract(p) - .5) / D;
    
    // march
    while(i++ < 99. && map(res * k))
        side += mask / abs(D),
        mask = step(side, min(side.yzx, side.zxy)),
        k += norm = mask * sign(D);
        
    // material
    d = dot(side, mask);
    q = abs(p - k + d * D);
    
    float border   = dot(max(q.yzx, q.zxy), mask) - .45,
          face     = smoothstep(10./r.y, .0, border) + 5.,
          deepFade = 1.5 / d - .02;
          
    glFragColor = deepFade * face * (norm.xyzx * .25 + .6); // pastel colors
}