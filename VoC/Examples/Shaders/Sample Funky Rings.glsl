#version 420

// original https://www.shadertoy.com/view/DldGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* "Synergy" by @kishimisu (2023) - https://www.shadertoy.com/view/ms3XWl 

   A 31-seconds seamless loop directed by trigonometry
*/

void main(void) {
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    vec2   g  = resolution.xy,
           o  = (F+F-g)/g.y/.7; 
    float  l  = 0., 
           f  = time*.05-2.;
    O = vec4(0.0);
    
    //a bit messy but yeah :)
    for (O.xyz = vec3(0.2, 0.05, 0.15); l < 55.; l++) {
    
        float group = mod(l, 10.) / 10.;
        float transition = fract(-time * 0.2 + group); 
        float depth = pow(transition, 0.5);
        vec2 offset = vec2(cos(l*f * 0.2), sin(l+f));
        float fade = smoothstep(0.5, 0.3, abs(0.5 - transition));
        vec2 p = o * (mod(l, 5.) + 1.) * depth + offset;
        float s = .08 + (1.0 - transition) * 0.4 * step(1., 1. / abs(mod(l, 40.)));
        float a = mod(atan(p.y, p.x) + time * (step(20., l) - 0.5), 3.14);
        float d = length(p) + 0.005 * sin(10. * a + time + l);
        O += clamp(fade * pow(.005, 1.0 - 0.2 * (sin(time + l) * 0.5 + 0.5)) * transition/abs(d - s)*(cos(l+ length(o) * 3. +vec4(0,1,2,0))+1.), 0.0, 1.0);
    }

    glFragColor=O;
}