#version 420

// original https://www.shadertoy.com/view/DsBczR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Flowing Wires by @kishimisu (2023) - https://www.shadertoy.com/view/DsBczR
   
   This is actually a 3D truchet pattern (with 1 tile and no variation)
*/

#define r(a) mat2(cos(a + vec4(0,33,11,0))) 

#define s(p) ( q = p,                                    \
    d = length(vec2(length(q.xy += .5)-.5, q.z)) - .01,  \
    q.yx *= r(round((atan(q.y,q.x)-T) * 3.8) / 3.8 + T), \
    q.x -= .5,                                           \
    O += (sin(t+T)*.1+.1)*(1.+cos(t+T*.5+vec4(0,1,2,0))) \
         / (.5 + pow(length(q)*50., 1.3))            , d ) // return d
   
void main(void) {
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    vec3  p, q,    R = vec3(resolution.xy,1.0);
    float i, t, d, T = time;

    for (O *= i, F += F - R.xy; i++ < 28.;          // raymarch for 28 iterations
        
        p = t * normalize(vec3(F*r(t*.1), R.y)),    // ray position
        p.zx *= r(T/4.), p.zy *= r(T/3.), p.x += T, // camera movement
                   
        t += min(min(s( p = fract(p) - .5 ),        // distance to torus + color (x3)
                     s( vec3(-p.y, p.zx)  )),
                     s( -p.zxy            ))
    );
    glFragColor=O;
}