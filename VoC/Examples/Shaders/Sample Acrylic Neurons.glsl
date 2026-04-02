#version 420

// original https://www.shadertoy.com/view/msyBWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define gyr(p) (dot(cos(p), sin(p.yzx)) + 1.35)
#define f(z) cos(z * vec2(.6, .5) - vec2(33, 0))

void main(void) {
    vec4 o = vec4(0.0);
    vec2 u = gl_FragCoord.xy;

    float i, dd, d, a, t = time * 5.; 
    vec3  p, r = vec3(resolution.xy,1.0);
          o *= .0;
          u = (u - r.xy / 2.) / r.y;
    
    while(i++ < 2e2) 
    
        p = vec3(u * a * .15, cos(t * .3) * 5. + 15. - a),
        dd = length(p) / 80. - .01,
        
        p.z = a + t,
        p.xy = (u * a + f(p.z) - f(t) - vec2(0, 4.5)),
        d = abs(gyr(p) / 4.) + .001,
        
        a += d,
        
        o += (( abs(
                    mod(vec4(6, 4, 2, 0) + p.z * 8., 6.) - 3.
                ) - 1. 
                   
              ) * .03 + (dd > d? .34: .9)
             ) / 1e2 / exp(25. * d);
            
            
    
    o *= o - length(u) / 2.;
    glFragColor=o;
}