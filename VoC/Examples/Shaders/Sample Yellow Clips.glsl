#version 420

// original https://www.shadertoy.com/view/XcffRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// playlist mecanics: https://www.shadertoy.com/playlist/mcSSDw
#define rot(a) mat2(cos(a + vec4(0, 11, 33, 0)))
#define t time * 2.

void main(void) {
    vec2 u = gl_FragCoord.xy;
    vec3 D, p, q, k, r = vec3(resolution.xy,1.0); 
    float s = 1., i, d, steps = 22., far = 60.,
          n = 8., ss = 1., pi = 3.14,
          a = 2. * pi / n,
          b = pi / n, eps = .01,
          w, j;
                  
    u = (u - r.xy / 2.) / r.y;
    vec4 O = vec4(0.);
    
    D = normalize(vec3(u, 3));
    p.z -= 31.;
    
    while(i++ < steps && s > eps && d < far) {
        w = 0., s = 1e5;
        while(w++ < n){
            k = p;
            k.xy *= rot(t * .1);
            k.zy *= rot(3.14/2. + cos(t * .3) * .6);
            k.xy *= rot(w * a);
            k.y += 7.;
            k.yz *= rot(ss * b / 1. - t * .5);
            ss = -ss;

            j = 0.;
            while(j++ < n)
                q = k,
                q.xy *= rot(j * a + t),
                q.x += 4.,
                q.xz *= rot(j * b),
                q = abs(q),
                q.y = abs(q.y) - 1.,
                s = min(s, length(
                               vec2(
                                   length(max(q.xy, 0.)) - .8, 
                                   q.z
                               )
                           ) - .1
                    );
        }
                    
        p += s * D;
        d += s;
    }
    
    if(s < eps)
        O.rg += 2. / exp(i / steps / .3);
        
    glFragColor = O;
}