#version 420

// original https://www.shadertoy.com/view/cdy3Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "The Core" by @kishimisu (2023) - https://www.shadertoy.com/view/cdy3Dd
// [440 chars]

void main(void) {
    vec4 O = vec4(0.0);
    vec2 o = gl_FragCoord.xy;
    vec2   c  = resolution.xy; 
           o  += o - c;
    vec3   r  ;    
    float  e  = 0., t, d, m = time * .5;
            
    for (O *= t = e; e++ < 1e2;                
        r = t*normalize(vec3(abs(o/c.y),1)),

        d  = length(r - vec3(0,0,15)) - 1.,        
        O += vec4(.2,.1,.04,0) / (1. + d/.1),
        
        r.z += m,
        r.xy = fract(r.xy*mat2(cos(
               sin(r.z)*sin(m)*.3+vec4(0,33,11,0))))-.5,
        
        t += d = min(d, length(r.xy) - .1),
        
        O += .05 * smoothstep(0., 1., cos(t*.1*(sin(m)+20.) + 
             vec4(0,1,2,0) * (.15+length(r.xy)*2.) - m) -.6) / 
             (1. + d) / exp(t*.1) * smoothstep(.2, 1., m*.2));

    glFragColor = O;
}
