#version 420

// original https://www.shadertoy.com/view/ddS3z3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
   @kishimisu - 2022 
   https://www.shadertoy.com/view/ddS3z3 
*/

#define c(a) (sin(a)*.5+.5)
#define g    (time*.5)

float b(vec3 p, vec3 s) { // box sdf
  vec3 q = abs(p) - s; return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.);
}

void main(void) {
    float a, r, t = 3.;
    
    vec2 n = resolution.xy; 
    for (a = 0.; a < 150. && t > .002*r && r < 50.; a++) {
        vec3 p = normalize(vec3((gl_FragCoord.xy-n*.5)/n.y*1.4, 1.))*r; p.z += g; 
        p.xy  *= mat2(cos(mix(c(g), -c(g), c((g-3.14)/2.))*r*.75 + vec4(0,33,11,0)));    
        r += t = max(b(fract(p+.5)-.5, vec3(mix(.2,.45,c(g)))),-b(p, vec2(1.1,1e9).xxy))*.85;         
    }
    glFragColor = vec4(cos(vec3(mix(2.05,1.85,c(g)),2.1,2.15)*r-g) * exp(-r*.06),1.0);
}
