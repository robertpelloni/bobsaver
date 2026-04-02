#version 420

// original https://www.shadertoy.com/view/csfSRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* @kishimisu - 2022
   https://www.shadertoy.com/view/csfSRN

   Playing around with raymarching, space repetition, 
   psychedelic colors and code golfing.
   
*/

/* Anti-aliasing code */

#define AA 2

#define _AA_START               \
vec3 tot;                       \
for (int j = 0; j < AA; j++)    \
for (int k = 0; k < AA; k++) {  \
vec2 f = vec2(float(j), float(k)) / float(AA) - 0.5;

#define _AA_END        \
} tot /= float(AA*AA); \
glFragColor = vec4(tot, 1.);

void main(void) { //WARNING - variables void (out vec4 O, vec2 F) { need changing to glFragColor and gl_FragCoord.xy
_AA_START
    float p, s, y, c, h = 3., 
                      e = time*.4+.8;
    
    vec2 r = resolution.xy,
         v = (gl_FragCoord.xy*2.-r-f)/r.y;
         
    for (s = 0.; s < 2e2 && abs(h) > .001 && p < 40.; s++) {
        vec3 o = p * normalize(vec3(1., v));
        c      = sin(e + p*.5)*.25;
        y      = c + .25;
        o.x   += e; 
        o.y    = abs(o.y);
        o      = fract(o) - .5;
        o.xy  *= mat2(cos(e + vec4(0,33,11,0)));
        o.y   += y/2.; 
        o.y   -= clamp(o.y, 0., y);     
        p += h = (length(o) - .1*(.75 + p*.1 + c))*.8;
    }
        
    tot.rgb += exp(-p*.15 - .5*length(v)) * (cos(p*(8.4 + 0.16*vec3(0,1,2)))*1.2+1.2);
_AA_END
}
