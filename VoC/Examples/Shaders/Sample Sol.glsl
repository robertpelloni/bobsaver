#version 420

// original https://www.shadertoy.com/view/dttcRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R(a) mat2(cos(a + vec4(0, 11, 33, 0)))
#define rot(p) p.yz *= R(C.y), p.xz *= R(C.x)
#define wmod(p, w)  mod(p, w) - w/2.

void main(void) {
    vec4 o = vec4(0.0);
    vec2 u = gl_FragCoord.xy;
    
    float j, l, d, dd = 1., t = time;
          
    vec3 r = vec3(resolution.xy,1.0), p, q,
         D = vec3((u - r.xy / 2.) / r.y, 1.25), 
         C = 3. * cos(.3 * t + vec3(0, 23, 21));
             
        vec3 f;
    o = vec4(1); p.z -= 12.;
    while(o.x > 0. && dd > .01) {
        q = p, 
        rot(q), 
        l = length(q.xy), 
        q.z = abs(q.z),
        
        abs(atan(q.z, l)) < 1. 
            ? q.xy = l * cos(wmod(atan(q.x, q.y), 1.256) + vec2(0, 33)), 
                q.xz *= R(-1.12), q 
            : q = q.yxz, 
        
        dd = min(
                length(q.xy) + .2 * q.z - 1., 
                length(q) - 2.25), 

        j = 1.;
        while(j < 64.) 
            f = p * j * 5., 
            sin(d * j) < .05
                ? rot(f), f
                : f,
            d = dot(cos(f), vec3(cos(t*.1))) / j / 10.,
            dd += abs(d),
            j += j;

        p += .5 * dd * D, 
        
        o -= vec4(1, 4, 8, 0) / 4e2;
    }
            
    o *= o * o * o * 1.4;
    glFragColor = o;
}