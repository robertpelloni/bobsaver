#version 420

// original https://www.shadertoy.com/view/MtfBDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Contrast speed illusion. Created by Reinder Nijhoff 2017
// @reindernijhoff
// 
// https://www.shadertoy.com/view/MtfBDN
//
// Both rectangles are moving at exactly the same speed.
//
// Based on the flash implementation by Jim Cash: https://scratch.mit.edu/projects/188838060/
//
// Research paper:
//
// https://quote.ucsd.edu/anstislab/files/2012/11/2001-Footsteps-and-inchworms.pdf
//

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float scale = resolution.x / 300.;
    
    vec3 c = vec3(mix(.7, round(fract(uv.x*20.*scale)-.02*scale), smoothstep(0.1,0.2,abs(fract(time*.05+.5)-.5))));
    
    float p = fract(time*.1/scale);
    float x = step(uv.x,p+.3/scale)*step(p,uv.x);
    
    c = mix(c, vec3(1,1,0), x*step(abs(uv.y-.3),.03));
    c = mix(c, vec3(0,0,0.7), x*step(abs(uv.y-.7),.03));
    
    glFragColor = vec4(c,1.0);
}
